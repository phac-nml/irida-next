# frozen_string_literal: true

module PersonalAccessTokens
  # Service used to create personal access tokens
  class CreateService < BaseService
    PersonalAccessTokenNameCreateError = Class.new(StandardError)
    PersonalAccessTokenScopeCreateError = Class.new(StandardError)
    attr_accessor :namespace, :bot_user, :personal_access_token

    def initialize(user, params, namespace = nil, bot_user = nil)
      super(user, params)

      @bot_user = bot_user
      @namespace = namespace
      @personal_access_token = PersonalAccessToken.new(params.merge(user: bot_user.nil? ? current_user : bot_user))
    end

    def execute
      authorize! current_user, to: :generate_bot_personal_access_token? if bot_user.nil?
      authorize! namespace, to: :generate_bot_personal_access_token? unless bot_user.nil?

      validate_params

      personal_access_token.save

      personal_access_token
    rescue PersonalAccessTokens::CreateService::PersonalAccessTokenNameCreateError => e
      personal_access_token.errors.add(:name, e.message)
      personal_access_token
    rescue PersonalAccessTokens::CreateService::PersonalAccessTokenScopeCreateError => e
      personal_access_token.errors.add(:scopes, e.message)
      personal_access_token
    end

    def validate_params
      if params[:name].blank?
        raise PersonalAccessTokenNameCreateError,
              I18n.t('services.personal_access_tokens.create.required.token_name')
      end

      return if params[:scopes].present?

      raise PersonalAccessTokenScopeCreateError,
            I18n.t('services.personal_access_tokens.create.required.scopes')
    end
  end
end
