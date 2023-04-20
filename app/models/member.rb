# frozen_string_literal: true

# entity class for Member
class Member < ApplicationRecord
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

  class << self
    # TODO: Remove this once authorization is setup and
    # the policy class will handle which access levels
    # to return
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
      Member.exists?(namespace: object_namespace.self_and_ancestors, user:,
                     access_level: Member::AccessLevel::OWNER)
    end

    def can_view?(user, object_namespace)
      Member.exists?(namespace: object_namespace.self_and_ancestors, user:)
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
    Member.where(namespace: namespace.ancestors, user_id:).order(:access_level).last
  end

  # Method to ensure we don't leave a group or project without an owner
  def last_namespace_owner_member
    return if destroyed_by_association
    return if access_level != Member::AccessLevel::OWNER
    return if Member.where(namespace: namespace.self_and_ancestors,
                           access_level: Member::AccessLevel::OWNER).many?

    errors.add(:base,
               I18n.t('activerecord.errors.models.member.destroy.last_member',
                      namespace_type: namespace.class.model_name.human))
    false
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
