# frozen_string_literal: true

# Controller for generating single use user personal access token page
class IntegrationAccessTokenController < ApplicationController
  before_action :ensure_enabled
  before_action :set_user

  layout 'devise'

  def index
    authorize! @user
    @personal_access_token = PersonalAccessToken.new(scopes: [])
  end

  def create
    respond_to do |format|
      if integration_host_allow_list.include? caller_identifier
        @personal_access_token = PersonalAccessTokens::CreateService.new(
          current_user,
          personal_access_token_params
        ).execute

        handle_token_creation(format)
      else # caller identifier not in allow list
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { new_personal_access_token: nil,
                                                          message: I18n.t('integration_access_tokens.create.denied') }
        end
      end
    end
  end

  private

  def handle_token_creation(format)
    if @personal_access_token.persisted?
      format.turbo_stream do
        render locals: { personal_access_token: PersonalAccessToken.new(scopes: []),
                         new_personal_access_token: @personal_access_token,
                         encoded_token: encoded_token,
                         target_host: caller_url }
      end
    else
      format.turbo_stream do
        error = I18n.t('integration_access_tokens.create.error', error: error_message(@personal_access_token))
        render status: :unprocessable_entity, locals: {
          new_personal_access_token: nil, message: error
        }
      end
    end
  end

  def ensure_enabled
    not_found unless Flipper.enabled?(:integration_access_token_generation)
  end

  def personal_access_token_params
    {
      name: SecureRandom.uuid.to_s,
      scopes: ['api'],
      expires_at: token_lifespan.days.from_now,
      integration: true,
      integration_host: caller_identifier
    }
  end

  def encoded_token
    Base64.encode64("#{current_user.email}:#{@personal_access_token.token}")
  end

  def set_user
    @user = current_user
  end

  def integration_host_allow_list
    Rails.configuration.cors_config['allowed_hosts'].pluck(:identifier)
  end

  def caller_identifier
    @caller_identifier ||= caller_identifier_from_request
  end

  def caller_identifier_from_request
    p = Rack::Utils.parse_query(URI(request.referer).query)
    return p['caller'] if p['caller']

    nil
  end

  def caller_url
    Rails.configuration.cors_config['allowed_hosts'].each do |x|
      return x[:url] if x[:identifier] == caller_identifier
    end
  end

  def token_lifespan
    Rails.configuration.cors_config['allowed_hosts'].each do |x|
      return x[:token_lifespan_days] if x[:identifier] == caller_identifier
    end
  end
end
