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

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      authorize! @namespace, to: :update_member?

      unless current_user != member.user
        raise MemberUpdateError, I18n.t('services.members.update.cannot_update_self',
                                        namespace_type: namespace.class.model_name.human)
      end

      if Member.effective_access_level(namespace, current_user) == Member::AccessLevel::MAINTAINER &&
         (params[:access_level].to_i > Member::AccessLevel::MAINTAINER)
        raise MemberUpdateError, I18n.t('services.members.update.role_not_allowed')
      end

      updated = member.update(params)

      if updated
        UpdateMembershipsJob.set(
          queue: :prioritized_queue
        ).perform_later(member.id)

        namespace_key = if member.namespace.group_namespace?
                          'group'
                        else
                          'namespaces_project_namespace'
                        end
        member.namespace.create_activity key: "#{namespace_key}.member.update", owner: current_user, parameters: {
          member_email: member.user.email,
          action: 'member_update'
        }
      end

      updated
    rescue Members::UpdateService::MemberUpdateError => e
      member.errors.add(:base, e.message)
      false
    end
  end
end
