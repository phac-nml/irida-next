# frozen_string_literal: true

# Purpose: To handle the user's personal access tokens
module Profiles
  # Controller for the user personal access tokens page
  class PersonalAccessTokensController < Profiles::ApplicationController
    layout 'profiles'

    before_action :active_access_tokens

    def index
      @personal_access_token = PersonalAccessToken.new(scopes: [])
    end

    def create
      @personal_access_token = PersonalAccessToken.new(personal_access_token_params.merge(user: current_user))

      respond_to do |format|
        if @personal_access_token.save
          format.turbo_stream do
            render locals: { personal_access_token: PersonalAccessToken.new(scopes: []),
                             new_personal_access_token: @personal_access_token }
          end
        else
          format.turbo_stream do
            render locals: { personal_access_token: @personal_access_token,
                             new_personal_access_token: nil }
          end
        end
      end
    end

    def revoke
      @personal_access_token = PersonalAccessToken.find(params[:id])
      @personal_access_token.revoke!

      respond_to do |format|
        format.turbo_stream
      end
    end

    private

    def personal_access_token_params
      params.require(:personal_access_token).permit(:name, :expires_at, scopes: [])
    end

    def active_access_tokens
      @active_access_tokens = current_user.personal_access_tokens.active
    end
  end
end
