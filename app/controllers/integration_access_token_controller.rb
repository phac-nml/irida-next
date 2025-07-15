# frozen_string_literal: true

# Controller for generating single use user personal access token page
class IntegrationAccessTokenController < ApplicationController
  before_action :set_user

  layout 'devise'

  def index
    authorize! @user
    @personal_access_token = PersonalAccessToken.new(scopes: [])
  end

  def create # rubocop:disable Metrics/MethodLength
    @personal_access_token = PersonalAccessTokens::CreateService.new(
      current_user,
      personal_access_token_params
    ).execute

    respond_to do |format|
      if @personal_access_token.persisted?
        format.turbo_stream do
          render locals: { personal_access_token: PersonalAccessToken.new(scopes: []),
                           new_personal_access_token: @personal_access_token }
        end
      else
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { personal_access_token: @personal_access_token,
                                                          new_personal_access_token: nil,
                                                          message: error_message(@personal_access_token) }
        end
      end
    end
  end

  private

  def personal_access_token_params
    now = Time.now
    {
      name: "integration_access_token_#{now.to_s}",
      scopes: ["api"],
      expires_at: now + 7.days
    }
  end

  def set_user
    @user = current_user
  end
end
