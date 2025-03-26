# frozen_string_literal: true

module Groups
  module Bots
    # Controller actions for Group Bot Personal Access Tokens
    class PersonalAccessTokensController < Groups::ApplicationController
      include BotPersonalAccessTokenActions

      respond_to :turbo_stream

      protected

      def namespace
        @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
        @namespace = @group
      end

      private

      def bot_personal_access_token_params
        params.expect(personal_access_token: [:name, :expires_at, { scopes: [] }])
      end
    end
  end
end
