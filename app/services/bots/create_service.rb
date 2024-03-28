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
        email: "#{@auth_object.namespace.type.downcase}_#{@auth_object.puid.downcase}_bot_#{SecureRandom.hex(5)}@iridanext.com", # rubocop:disable Layout/LineLength
        user_type: User.user_types[:project_bot],
        first_name: @auth_object.namespace.type.downcase,
        last_name: 'Bot'
      }

      @bot_user_account = User.new(user_params)
    end

    def execute
      authorize! auth_object, to: :create_bot_accounts?

      validate_params

      bot_user_account = create_bot_account

      personal_access_token = create_bot_user_account_pat(bot_user_account)

      member = add_bot_to_namespace_members(bot_user_account)

      { bot_user_account:, personal_access_token:, member: }
    rescue Bots::CreateService::BotAccountCreateError => e
      @bot_user_account.errors.add(:base, e.message)
      { bot_user_account: @bot_user_account, personal_access_token: nil, member: nil }
    end

    def validate_params
      raise BotAccountCreateError, I18n.t('services.bots.create.required.token_name') if params[:token_name].blank?

      raise BotAccountCreateError, I18n.t('services.bots.create.required.scopes') if params[:scopes].blank?

      if params[:access_level].blank?
        raise BotAccountCreateError,
              I18n.t('services.bots.create.required.access_level')
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
        name: params[:token_name],
        expires_at: params[:expires_at],
        scopes: params[:scopes]
      }

      PersonalAccessToken.create!(personal_access_token_params.merge(user: bot_user_account))
    end

    def add_bot_to_namespace_members(bot_user_account)
      member_params = {
        user: bot_user_account,
        namespace: auth_object.namespace,
        access_level: params[:access_level]
      }
      Members::CreateService.new(current_user, auth_object.namespace, member_params).execute
    end
  end
end
