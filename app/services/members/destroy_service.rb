# frozen_string_literal: true

module Members
  # Service used to Delete Members
  class DestroyService < BaseService
    MemberDestroyError = Class.new(StandardError)
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      auth_method = namespace.group_namespace? ? :allowed_to_modify_group? : :allowed_to_modify_project_namespace?
      action_allowed_for_user(namespace, auth_method)

      unless current_user != member.user
        raise MemberDestroyError, I18n.t('services.members.destroy.cannot_remove_self',
                                         namespace_type: namespace.class.model_name.human)
      end

      unless Member.namespace_owners_include_user?(current_user, namespace) ||
             (Member.user_has_namespace_maintainer_access?(current_user,
                                                           namespace) &&
                                                           member.access_level <= Member::AccessLevel::MAINTAINER)
        raise MemberDestroyError,
              I18n.t('services.members.destroy.role_not_allowed')
      end

      member.destroy
    rescue Members::DestroyService::MemberDestroyError => e
      member.errors.add(:base, e.message)
      false
    end
  end
end
