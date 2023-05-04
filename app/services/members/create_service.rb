# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    MemberCreateError = Class.new(StandardError)
    attr_accessor :namespace, :member

    def initialize(user = nil, namespace = nil, params = {})
      super(user, params)
      @namespace = namespace
      @member = Member.new(params.merge(created_by: current_user, namespace:))
    end

    def execute # rubocop:disable Metrics/AbcSize
      auth_method = namespace.group_namespace? ? :allowed_to_modify_group? : :allowed_to_modify_project_namespace?
      action_allowed_for_user(namespace, auth_method)

      if member.namespace.owner != current_user &&
         (Member.user_has_namespace_maintainer_access?(current_user,
                                                       namespace) &&
            (member.access_level > Member::AccessLevel::MAINTAINER))
        raise MemberCreateError, I18n.t('services.members.create.role_not_allowed',
                                        namespace_type: namespace.class.model_name.human)
      end

      member.save
      member
    rescue Members::CreateService::MemberCreateError => e
      member.errors.add(:base, e.message)
      member
    end
  end
end
