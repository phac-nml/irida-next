# frozen_string_literal: true

module Members
  # Service used to Update Members
  class DestroyService < BaseService
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute
      if (current_user == member.user) || namespace.owners.exclude?(current_user)
        member.errors.add(:base, error_message)
      else
        member.destroy
      end
    end

    def members
      if member.type == 'GroupMember'
        namespace.group_members
      else
        namespace.project_members
      end
    end

    def error_message
      if current_user == member.user
        I18n.t('services.members.destroy.cannot_remove_self',
               namespace_type: namespace.type.downcase)
      else
        I18n.t('services.members.destroy.no_permission', namespace_type: namespace.type.downcase)
      end
    end
  end
end
