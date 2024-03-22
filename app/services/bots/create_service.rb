# frozen_string_literal: true

module Bots
  # Service used to Create Bot Accounts
  class CreateService < BaseService
    BotAccountCreateError = Class.new(StandardError)
    attr_accessor :auth_object, :bot_user_account

    def initialize(user = nil, auth_object = nil, params = {})
      super(user, params)
      @auth_object = auth_object

      user_params = {
        email: "#{params[:bot_username]}@iridanext.com",
        user_type: User.user_types[:project_bot],
        first_name: params[:first_name],
        last_name: params[:last_name]
      }

      @bot_user_account = User.new(user_params)
    end

    def execute
      authorize! auth_object, to: :create_bot_accounts?

      validate_params

      bot_user_account = create_bot_account

      create_bot_user_account_pat(bot_user_account)

      bot_user_account
    rescue Bots::CreateService::BotAccountCreateError => e
      @bot_user_account.errors.add(:base, e.message)
      @bot_user_account
    end

    def validate_params # rubocop:disable Metrics/MethodLength
      if params[:bot_username].blank?
        raise BotAccountCreateError,
              'Unable to create bot account as the bot username is required'
      end

      if params[:first_name].blank?
        raise BotAccountCreateError,
              'Unable to create bot account as the bot first name is required'
      end

      if params[:last_name].blank?
        raise BotAccountCreateError,
              'Unable to create bot account as the bot last name is required'
      end

      if params[:scopes].blank?
        raise BotAccountCreateError,
              'Unable to create bot account as the bot API scope must be selected'
      end

      true
    end

    def create_bot_account
      bot_user_account.skip_password_validation = true
      bot_user_account.save!

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
