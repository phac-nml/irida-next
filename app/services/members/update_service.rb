# frozen_string_literal: true

module Members
  # Service used to Update Members
  class UpdateService < BaseService
    MemberUpdateError = Class.new(StandardError)
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      # TODO: Update params to only keep required values
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute # rubocop:disable Metrics/AbcSize
      auth_method = namespace.group_namespace? ? :allowed_to_modify_group? : :allowed_to_modify_project_namespace?
      action_allowed_for_user(namespace, auth_method)

      unless current_user != member.user
        raise MemberUpdateError, I18n.t('services.members.update.cannot_update_self',
                                        namespace_type: namespace.class.model_name.human)
      end

      member.update(params)
    rescue Members::UpdateService::MemberUpdateError => e
      member.errors.add(:base, e.message)
      false
    end
  end
end
