# frozen_string_literal: true

# Purpose: To handle the user's personal access tokens
module Profiles
  # Controller for the user personal access tokens page
  class PersonalAccessTokensController < Profiles::ApplicationController
    layout 'profiles'

    before_action :active_access_tokens

    def index
      @personal_access_token = PersonalAccessToken.new(user: current_user, scopes: [])
    end

    def create; end

    def revoke; end

    private

    def personal_access_token_params
      params.require(:personal_access_token).permit(:name, :expires_at, scopes: [])
    end

    def active_access_tokens
      @active_access_tokens = current_user.personal_access_tokens.active
    end
  end
end
