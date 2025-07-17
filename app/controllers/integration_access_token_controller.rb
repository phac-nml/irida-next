# frozen_string_literal: true

# Controller for generating single use user personal access token page
class IntegrationAccessTokenController < ApplicationController
  before_action :set_user

  layout 'devise'

  def index
    authorize! @user
    @personal_access_token = PersonalAccessToken.new(scopes: [])
  end

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    respond_to do |format| # rubocop:disable Metrics/BlockLength
      if integration_host_allow_list.include? caller
        @personal_access_token = PersonalAccessTokens::CreateService.new(
          current_user,
          personal_access_token_params
        ).execute

        if @personal_access_token.persisted?
          format.turbo_stream do
            render locals: { personal_access_token: PersonalAccessToken.new(scopes: []),
                             new_personal_access_token: @personal_access_token,
                             encoded_token: encoded_token,
                             target_host: caller }
          end
        else
          format.turbo_stream do
            error = I18n.t('integration_access_tokens.create.error', error: error_message(@personal_access_token))
            render status: :unprocessable_entity, locals: {
              new_personal_access_token: nil, message: error
            }
          end
        end
      else # caller url not in allow list
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { new_personal_access_token: nil,
                                                          message: I18n.t('integration_access_tokens.create.denied') }
        end
      end
    end
  end

  private

  def personal_access_token_params
    {
      name: SecureRandom.uuid.to_s,
      scopes: ['api'],
      expires_at: token_lifespan.days.from_now,
      integration: true,
      integration_host: URI(caller).host.to_s
    }
  end

  def encoded_token
    Base64.encode64("#{current_user.email}:#{@personal_access_token.token}")
  end

  def set_user
    @user = current_user
  end

  def integration_host_allow_list
    Rails.configuration.cors_config['allowed_hosts'].pluck(:url)
  end

  def caller
    @caller ||= caller_from_request
  end

  def caller_from_request
    p = Rack::Utils.parse_query(URI(request.referer).query)
    return p['caller'] if p['caller']

    nil
  end

  def token_lifespan
    Rails.configuration.cors_config['allowed_hosts'].each do |x|
      return x[:token_lifespan_days] if x[:url] == caller
    end
  end
end
