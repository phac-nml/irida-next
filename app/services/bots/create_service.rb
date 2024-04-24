# frozen_string_literal: true

module Bots
  # Service used to Create Bot Accounts
  class CreateService < BaseService
    BotAccountCreateError = Class.new(StandardError)
    attr_accessor :namespace, :bot_user_account

    def initialize(user = nil, namespace = nil, bot_type = nil, params = {}) # rubocop:disable Metrics/ParameterLists
      super(user, params)
      @namespace = namespace

      current_count = @namespace.namespace_bots.with_deleted.count

      user_params = {
        user_type: bot_type,
        first_name: namespace.puid,
        last_name: "Bot #{format('%03d', (current_count + 1))}"
      }

      @bot_user_account = User.new(user_params)

      @is_automation_bot = @bot_user_account.automation_bot?

      bot_text = @is_automation_bot ? 'automation_bot' : "bot_#{format('%03d', (current_count + 1))}"

      @bot_user_account.email = "#{namespace.puid}_#{bot_text}@iridanext.com"
    end

    def execute
      authorize! namespace, to: :create_bot_accounts?

      validate_params

      bot_user_account = create_bot_account

      personal_access_token = create_bot_user_account_pat(bot_user_account) unless @is_automation_bot

      member = add_bot_to_namespace_members(bot_user_account)

      { bot_user_account:, personal_access_token:, member: }
    rescue Bots::CreateService::BotAccountCreateError => e
      @bot_user_account.errors.add(:base, e.message)
      { bot_user_account: @bot_user_account, personal_access_token: nil, member: nil }
    end

    def validate_params
      unless @is_automation_bot
        raise BotAccountCreateError, I18n.t('services.bots.create.required.token_name') if params[:token_name].blank?

        raise BotAccountCreateError, I18n.t('services.bots.create.required.scopes') if params[:scopes].blank?
      end

      if params[:access_level].blank?
        raise BotAccountCreateError,
              I18n.t('services.bots.create.required.access_level')
      end

      true
    end

    def create_bot_account
      bot_user_account.skip_password_validation = true
      bot_user_account.save!

      NamespaceBot.create!(user: bot_user_account, namespace:) if bot_user_account.persisted?

      bot_user_account
    end

    def create_bot_user_account_pat(bot_user_account)
      personal_access_token_params = {
        name: params[:token_name],
        scopes: params[:scopes],
        expires_at: params[:expires_at]
      }

      PersonalAccessTokens::CreateService.new(current_user, personal_access_token_params, namespace,
                                              bot_user_account).execute
    end

    def add_bot_to_namespace_members(bot_user_account)
      member_params = {
        user: bot_user_account,
        namespace:,
        access_level: params[:access_level]
      }
      Members::CreateService.new(current_user, namespace, member_params).execute
    end
  end
end
