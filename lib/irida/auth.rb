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

    def authorize_view_group!
      action_allowed_for_user(@group)
    end

    def authorize_create_subgroup!
      action_allowed_for_user(@group) unless @group.nil?
    end

    def authorize_modify_project!
      action_allowed_for_user(@project)
    end

    def authorize_view_project!
      action_allowed_for_user(@project)
    end

    def authorize_user_profile_access!
      action_allowed_for_user(@user)
    end

    protected

    def action_allowed_for_user(auth_object, auth_method = nil)
      authorize! auth_object if auth_method.nil?
      authorize! auth_object, to: auth_method
    end
  end
end
