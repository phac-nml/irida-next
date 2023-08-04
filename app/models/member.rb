# frozen_string_literal: true

# entity class for Member
class Member < ApplicationRecord # rubocop:disable Metrics/ClassLength
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

  after_update :update_descedant_memberships
  before_destroy :last_namespace_owner_member

  delegate :project, to: :project_namespace

  class << self # rubocop:disable Metrics/ClassLength
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

    def can_modify?(user, object_namespace)
      if object_namespace.project_namespace?
        Member.exists?(namespace: object_namespace.parent&.self_and_ancestor_ids,
                       user:, access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER]) ||
          Member.exists?(namespace: object_namespace, user:,
                         access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER])
      elsif object_namespace.group_namespace?
        Member.exists?(namespace: object_namespace.self_and_ancestor_ids, user:,
                       access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER])
      end
    end

    def can_create?(user, object_namespace)
      if object_namespace.project_namespace?
        Member.exists?(namespace: object_namespace.parent&.self_and_ancestor_ids,
                       user:, access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER]) ||
          Member.exists?(namespace: object_namespace, user:,
                         access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER])
      elsif object_namespace.group_namespace?
        Member.exists?(namespace: object_namespace.self_and_ancestor_ids, user:,
                       access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER])
      end
    end

    def can_view?(user, object_namespace)
      if object_namespace.project_namespace?
        Member.exists?(namespace: object_namespace.parent&.self_and_ancestor_ids, user:) ||
          Member.exists?(
            namespace: object_namespace, user:
          )
      elsif object_namespace.group_namespace?
        Member.exists?(
          namespace: object_namespace.self_and_ancestor_ids, user:
        )
      end
    end

    def can_destroy?(user, object_namespace)
      namespace_owners_include_user?(user, object_namespace)
    end

    def can_transfer?(user, object_namespace)
      namespace_owners_include_user?(user, object_namespace)
    end

    def can_transfer_into_namespace?(user, object_namespace)
      if object_namespace.project_namespace?
        if object_namespace.parent.user_namespace?
          object_namespace.parent.owner == user
        else
          Member.exists?(namespace: object_namespace.parent&.self_and_ancestor_ids,
                         user:, access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER]) ||
            Member.exists?(namespace: object_namespace, user:,
                           access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER])
        end
      elsif object_namespace.group_namespace?
        Member.exists?(namespace: object_namespace.self_and_ancestor_ids, user:,
                       access_level: [Member::AccessLevel::MAINTAINER, Member::AccessLevel::OWNER])
      end
    end

    def can_transfer_sample?(user, object_namespace)
      namespace_owners_include_user?(user, object_namespace)
    end

    def can_transfer_sample_to_project?(user, object_namespace)
      can_transfer_into_namespace?(user, object_namespace)
    end

    def can_share_namespace_with_group?(user, object_namespace)
      can_modify?(user, object_namespace)
    end

    def can_unshare_namespace_with_group?(user, object_namespace)
      can_modify?(user, object_namespace)
    end

    def namespace_owners_include_user?(user, namespace)
      if namespace.project_namespace?
        Member.exists?(
          namespace:, user:,
          access_level: Member::AccessLevel::OWNER
        ) || Member.exists?(
          namespace: namespace.parent&.self_and_ancestor_ids, user:,
          access_level: Member::AccessLevel::OWNER
        )
      elsif namespace.group_namespace?
        Member.exists?(
          namespace: namespace.self_and_ancestor_ids, user:,
          access_level: Member::AccessLevel::OWNER
        )
      end
    end

    def user_has_namespace_maintainer_access?(user, namespace)
      if namespace.project_namespace?
        Member.exists?(
          namespace:, user:,
          access_level: Member::AccessLevel::MAINTAINER
        ) || Member.exists?(
          namespace: namespace.parent&.self_and_ancestor_ids, user:,
          access_level: Member::AccessLevel::MAINTAINER
        )
      else
        Member.exists?(user:, namespace: namespace.self_and_ancestor_ids,
                       access_level: Member::AccessLevel::MAINTAINER)
      end
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
  def last_namespace_owner_member
    return if destroyed_by_association
    return if access_level != Member::AccessLevel::OWNER
    return if Member.where(namespace:, access_level: Member::AccessLevel::OWNER).many?
    return if Member.where(namespace: namespace.parent&.self_and_ancestor_ids,
                           access_level: Member::AccessLevel::OWNER).any?

    errors.add(:base,
               I18n.t('activerecord.errors.models.member.destroy.last_member',
                      namespace_type: namespace.class.model_name.human))
    throw :abort
  end

  # Method to update descendant membership access levels so they aren't less than the parent group
  def update_descedant_memberships
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
    ANALYST        = 20 # Can modify data in project but cannot add members
    MAINTAINER     = 30 # Can grant access to other users upto their level
    OWNER          = 40 # Full control

    class << self
      def all_values_with_owner
        access_level_options_owner.values
      end

      def access_level_options
        {
          I18n.t('activerecord.models.member.access_level.guest') => GUEST,
          I18n.t('activerecord.models.member.access_level.analyst') => ANALYST,
          I18n.t('activerecord.models.member.access_level.maintainer') => MAINTAINER
        }
      end

      def access_level_options_owner
        access_level_options.merge(
          I18n.t('activerecord.models.member.access_level.owner') => OWNER
        )
      end

      # Method to return the human readable access level (passed in as a numeric value)
      def human_access(access_level)
        access_level_options_owner.key(access_level).to_s
      end
    end
  end
end
