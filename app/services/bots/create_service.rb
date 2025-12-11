# frozen_string_literal: true

module Bots
  # Service used to Create Bot Accounts
  class CreateService < BaseService
    attr_accessor :namespace, :bot_user_account

    def initialize(user = nil, namespace = nil, bot_type = nil, params = {}) # rubocop:disable Metrics/ParameterLists
      super(user, params)
      @namespace = namespace

      current_count = @namespace.namespace_bots.with_deleted.count

      is_automation_bot = HasUserType::AUTOMATION_BOT_USER_TYPES.include?(bot_type)

      bot_text = is_automation_bot ? 'automation_bot' : "bot_#{format('%03d', current_count + 1)}"

      set_default_params(bot_text, bot_type, current_count)
    end

    def execute
      authorize! namespace, to: :create_bot_accounts?

      NamespaceBot.create(params)
    end

    private

    def set_default_params(bot_text, bot_type, current_count) # rubocop:disable Metrics/AbcSize
      @params[:namespace] = namespace
      @params[:user_attributes] ||= {}
      @params[:user_attributes].merge!({
                                         email: "#{namespace.puid}_#{bot_text}@iridanext.com",
                                         user_type: bot_type,
                                         first_name: namespace.puid,
                                         last_name: "Bot #{format('%03d', current_count + 1)}"
                                       })
      @params[:user_attributes][:members_attributes] ||= {}
      @params[:user_attributes][:members_attributes][:'0'] ||= {}
      @params[:user_attributes][:members_attributes][:'0'].merge!({ created_by: current_user, namespace: namespace })
    end
  end
end
