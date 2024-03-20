# frozen_string_literal: true

module Bots
  # Service used to Create Bot Accounts
  class CreateService < BaseService
    BotAccountCreateError = Class.new(StandardError)
    attr_accessor :auth_object

    def initialize(user = nil, auth_object = nil, params = {})
      super(user, params)
      @auth_object = auth_object
    end

    def execute # rubocop:disable Metrics/MethodLength
      # Authorize if current user is allowed to create bot account
      authorize! auth_object, to: :create_bot_accounts?

      # Create user with bot account user_type
      user_params = {
        email: "#{params[:bot_username]}@iridanext.com",
        user_type: 1,
        first_name: 'Project',
        last_name: 'Bot'
      }

      bot_user_account = User.new(user_params)
      bot_user_account.save(validate: false)

      # Create PAT for user with scope params
      personal_access_token_params = {
        name: params[:bot_username],
        expires_at: nil,
        scopes: params[:scopes]
      }
      PersonalAccessToken.create!(personal_access_token_params.merge(user: bot_user_account))
    rescue Bots::CreateService::BotAccountCreateError => e
      false
    end
  end
end
