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

    def execute
      authorize! auth_object, to: :create_bot_accounts?

      bot_user_account = create_bot_account

      create_bot_user_account_pat(bot_user_account)
    rescue Bots::CreateService::BotAccountCreateError => e
      auth_object.errors.add(:base, e.message)
      false
    end

    def create_bot_account
      user_params = {
        email: "#{params[:bot_username]}@iridanext.com",
        user_type: 2,
        first_name: 'Project',
        last_name: 'Bot'
      }

      bot_user_account = User.new(user_params)
      bot_user_account.save(validate: false)

      bot_user_account
    end

    def create_bot_user_account_pat(bot_user_account)
      personal_access_token_params = {
        name: params[:bot_username],
        expires_at: nil,
        scopes: params[:scopes]
      }
      PersonalAccessToken.create!(personal_access_token_params.merge(user: bot_user_account))
    end
  end
end
