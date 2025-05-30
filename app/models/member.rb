# frozen_string_literal: true

# entity class for Member
class Member < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include TrackActivity

  has_logidze
  acts_as_paranoid

  belongs_to :user
  belongs_to :namespace, autosave: true
  belongs_to :created_by, class_name: 'User'

  belongs_to :group, optional: true, foreign_key: :namespace_id # rubocop:disable Rails/InverseOf
  belongs_to :project_namespace, optional: true, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

  validates :access_level, presence: true
  validates :access_level, inclusion: { in: proc { AccessLevel.all_values_with_owner } }
  validates :user_id, uniqueness: { scope: :namespace_id }

  validate :validate_namespace
  validate :higher_access_level_than_group

  before_destroy :last_namespace_owner_member

  delegate :project, to: :project_namespace

  scope :for_namespace_and_ancestors, lambda { |namespace = nil|
                                        where(namespace:).or(where(namespace: namespace.parent&.self_and_ancestors))
                                      }

  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.zone.now.beginning_of_day) }

  scope :without_automation_bots, lambda {
                                    joins(:user).where.not(
                                      user: { user_type: User.user_types[:project_automation_bot] }
                                    )
                                  }

  class << self
    def access_levels(member)
      case member.access_level
      when AccessLevel::OWNER
        AccessLevel.access_level_options_owner
      when AccessLevel::MAINTAINER
        AccessLevel.access_level_options
      else
        {}
      end
    end

    def effective_access_level(namespace, user, include_group_links = true) # rubocop:disable Metrics/CyclomaticComplexity,Style/OptionalBooleanParameter
      return AccessLevel::OWNER if namespace.parent&.user_namespace? && namespace.parent.owner == user

      access_level = Member.for_namespace_and_ancestors(namespace).not_expired
                           .where(user:).order('access_level desc').select(:access_level).first&.access_level

      access_level = access_level_in_namespace_group_links(user, namespace) if include_group_links && access_level.nil?

      access_level.nil? ? AccessLevel::NO_ACCESS : access_level
    end

    def access_level_in_namespace_group_links(user, namespace)
      effective_namespace_group_link = NamespaceGroupLink.for_namespace_and_ancestors(namespace)
                                                         .where(group: user.groups.self_and_descendants)
                                                         .not_expired.order(:group_access_level).last

      if effective_namespace_group_link.nil?
        AccessLevel::NO_ACCESS
      else
        [effective_namespace_group_link.group_access_level,
         Member.effective_access_level(effective_namespace_group_link&.group, user)].min
      end
    end

    def user_emails(namespace, locale)
      user_memberships = Member.for_namespace_and_ancestors(namespace).not_expired
      users = User.human_users.where(id: user_memberships.select(:user_id), locale:).distinct
      users.pluck(:email)
    end

    def manager_emails(namespace, locale, access_level = Member::AccessLevel.manageable, member = nil) # rubocop:disable Metrics/AbcSize
      manager_memberships = Member.for_namespace_and_ancestors(namespace).not_expired
                                  .where(access_level:)
      managers = if member
                   User.human_users.where(id: manager_memberships.select(:user_id), locale:)
                       .and(User.where.not(id: member.user.id)).distinct
                 else
                   User.human_users.where(id: manager_memberships.select(:user_id), locale:).distinct
                 end
      manager_emails = managers.pluck(:email)

      if namespace.parent&.user_namespace? && (namespace.parent&.owner&.locale == locale.to_s)
        manager_emails << namespace.parent.owner.email
      end

      manager_emails
    end

    def ransackable_attributes(_auth_object = nil)
      %w[access_level created_at expires_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[user namespace group]
    end
  end

  def validate_namespace
    # Only Groups and Projects should have members
    return if %w[Group Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have members')
  end

  def higher_access_level_than_group
    return unless highest_group_member && highest_group_member.access_level > access_level

    errors.add(:access_level, I18n.t('activerecord.errors.models.member.attributes.access_level.invalid',
                                     user: user.email,
                                     access_level: AccessLevel.human_access(highest_group_member.access_level),
                                     group_name: highest_group_member.group.name))
  end

  # Find the user's group member with a highest access level
  def highest_group_member
    if namespace.project_namespace?
      Member.where(namespace_id: namespace.parent.self_and_ancestor_ids, user_id:).order(:access_level).last
    else
      Member.where(namespace_id: namespace.ancestor_ids, user_id:).order(:access_level).last
    end
  end

  # Method to ensure we don't leave a group or project without an owner
  def last_namespace_owner_member # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    return if destroyed_by_association
    return if access_level != Member::AccessLevel::OWNER
    return if namespace.parent&.user_namespace?
    return if Member.where(namespace:, access_level: Member::AccessLevel::OWNER).many?
    return if Member.where(namespace: namespace.parent&.self_and_ancestor_ids,
                           access_level: Member::AccessLevel::OWNER).any?

    errors.add(:base,
               I18n.t('activerecord.errors.models.member.destroy.last_member',
                      namespace_type: namespace.class.model_name.human))
    throw :abort
  end

  # Method to update descendant membership access levels so they aren't less than the parent group
  def update_descendant_memberships
    return unless namespace.group_namespace?

    descendants_membership = Member.where(user_id:,
                                          namespace: Namespace.where(id: namespace_id).self_and_descendants)

    descendants_membership.each do |descendant_member|
      descendant_member.update(access_level:) if descendant_member.access_level < access_level
    end
  end

  # class for member access levels
  class AccessLevel
    NO_ACCESS      = 0  # Access is disabled
    GUEST          = 10 # Read Only access
    UPLOADER       = 20 # Allows access to the api for the uploader
    ANALYST        = 30 # Can modify data in project but cannot add members
    MAINTAINER     = 40 # Can grant access to other users upto their level
    OWNER          = 50 # Full control

    class << self
      def all_values_with_owner
        access_level_options_owner.values
      end

      def access_level_options
        {
          I18n.t('activerecord.models.member.access_level.guest') => GUEST,
          I18n.t('activerecord.models.member.access_level.uploader') => UPLOADER,
          I18n.t('activerecord.models.member.access_level.analyst') => ANALYST,
          I18n.t('activerecord.models.member.access_level.maintainer') => MAINTAINER
        }
      end

      def access_level_options_owner
        access_level_options.merge(
          I18n.t('activerecord.models.member.access_level.owner') => OWNER
        )
      end

      def access_level_options_for_user(namespace, user)
        effective_access_level = Member.effective_access_level(namespace, user)

        if effective_access_level < MAINTAINER
          {}
        elsif effective_access_level == MAINTAINER
          access_level_options
        else
          access_level_options_owner
        end
      end

      # Method to return the human readable access level (passed in as a numeric value)
      def human_access(access_level)
        access_level_options_owner.key(access_level).to_s
      end

      def manageable
        [MAINTAINER, OWNER]
      end
    end
  end
end
