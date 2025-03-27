# frozen_string_literal: true

module Projects
  module Bots
    # Controller actions for Project Bot Personal Access Tokens
    class PersonalAccessTokensController < Projects::ApplicationController
      include BotPersonalAccessTokenActions

      respond_to :turbo_stream

      protected

      def namespace
        path = [params[:namespace_id], params[:project_id]].join('/')
        @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
        @namespace = @project.namespace
      end

      private

      def bot_personal_access_token_params
        params.expect(personal_access_token: [:name, :expires_at, { scopes: [] }])
      end
    end
  end
end
