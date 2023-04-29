# frozen_string_literal: true

module Irida
  # Module to encapsulate auth for IRIDA
  module Auth
    # Scopes used for IRIDA
    API_SCOPE = :api
    READ_API_SCOPE = :read_api
    API_SCOPES = [API_SCOPE, READ_API_SCOPE].freeze

    class << self
      def all_available_scopes
        API_SCOPES
      end
    end

    def authorize_modify_group!
      action_allowed_for_user(@group)
    end

    def authorize_create_group!
      action_allowed_for_user(@group) unless @group&.parent.nil?
    end

    def authorize_view_group!
      action_allowed_for_user(@group)
    end

    def authorize_owner_namespace!
      if @group.nil?
        action_allowed_for_user(@project)
      else
        action_allowed_for_user(@group)
      end
    end

    def authorize_modify_project!
      action_allowed_for_user(@project)
    end

    def authorize_view_members!
      authorize! @namespace, to: :allowed_to_view_members?
    end

    def authorize_destroy_members!
      authorize! @namespace, to: :allowed_to_modify_members?
    end

    def authorize_view_samples!
      authorize! @project, to: :allowed_to_view_samples?
    end

    def authorize_sample_modification!
      authorize! @project, to: :allowed_to_modify_samples?
    end

    def authorize_view_project!
      action_allowed_for_user(@project)
    end

    def authorize_user_profile_access!
      action_allowed_for_user(@user)
    end

    def authorize_transfer_project!
      action_allowed_for_user(@project)
    end

    protected

    def action_allowed_for_user(auth_object)
      authorize! auth_object
    end
  end
end
