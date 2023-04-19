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

    def authorize_owner_group!
      authorize! @group
    end

    def authorize_create_group!
      authorize! @group unless @group&.parent.nil?
    end

    def authorize_view_group!
      authorize! @group
    end

    def authorize_owner_namespace!
      if !@group.nil?
        authorize! @group
      elsif !@project.nil?
        authorize! @project
      end
    end

    def authorize_view_members!
      if !@namespace.nil?
        authorize! @namespace, to: :allowed_to_view_members?
      elsif !@project.nil?
        authorize! @project, to: :allowed_to_view_members?
      end
    end

    def authorize_view_samples!
      authorize! @project, to: :allowed_to_view_samples?
    end

    def authorize_sample_modification!
      authorize! @project, to: :allowed_to_modify_samples?
    end

    def authorize_view_project!
      authorize! @project
    end

    def authorize_user_profile_access!
      authorize! @user
    end
  end
end
