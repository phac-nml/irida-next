# frozen_string_literal: true

# entity class for Member
class Member < ApplicationRecord
  belongs_to :user
  belongs_to :namespace, autosave: true
  belongs_to :created_by, class_name: 'User'

  validates :access_level, presence: true
  validates :access_level, inclusion: { in: proc { AccessLevel.all_values_with_owner } }
  validates :user_id, uniqueness: { scope: :namespace_id }

  validate :validate_namespace

  class << self
    def sti_class_for(type_name)
      case type_name
      when Members::GroupMember.sti_name
        Members::GroupMember
      when Members::ProjectMember.sti_name
        Members::ProjectMember
      end
    end

    def access_levels(member_user, current_user_owner)
      case current_user_owner || member_user.access_level
      when current_user_owner || AccessLevel::OWNER
        AccessLevel.access_level_options_owner
      when AccessLevel::MAINTAINER
        AccessLevel.access_level_options
      end
    end
  end

  def validate_namespace
    # Only Groups and Projects should have members
    return if %w[Group Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have members')
  end

  # class for member access levels
  class AccessLevel
    NO_ACCESS      = 0  # Access is disabled
    GUEST          = 10 # Read Only access
    ANALYST        = 20 # Can modify data in project but cannot add members
    MAINTAINER     = 30 # Can grant access to other users upto their level
    OWNER          = 40 # Full control

    class << self
      def all_values_without_owner
        access_level_options.values
      end

      def all_values_with_owner
        access_level_options_owner.values
      end

      def access_level_options
        {
          I18n.t('activerecord.models.member.access_level.no_access') => NO_ACCESS,
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
    end
  end
end
