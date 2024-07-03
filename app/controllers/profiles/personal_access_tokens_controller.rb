# frozen_string_literal: true

# Purpose: To handle the user's personal access tokens
module Profiles
  # Controller for the user personal access tokens page
  class PersonalAccessTokensController < Profiles::ApplicationController
    before_action :active_access_tokens

    def index
      authorize! @user
      @personal_access_token = PersonalAccessToken.new(scopes: [])
    end

    def create
      @personal_access_token = PersonalAccessTokens::CreateService.new(current_user,
                                                                       personal_access_token_params).execute

      respond_to do |format|
        if @personal_access_token.persisted?
          format.turbo_stream do
            render locals: { personal_access_token: PersonalAccessToken.new(scopes: []),
                             new_personal_access_token: @personal_access_token }
          end
        else
          format.turbo_stream do
            render status: :unprocessable_entity, locals: { personal_access_token: @personal_access_token,
                                                            new_personal_access_token: nil }
          end
        end
      end
    end

    def revoke
      authorize! @user
      @personal_access_token = current_user.personal_access_tokens.find(params[:id])

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

    def current_page
      @current_page = t(:'profiles.sidebar.access_tokens')
    end
  end
end
