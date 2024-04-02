# frozen_string_literal: true

module Bots
  # Service used to Delete Projects
  class DestroyService < BaseService
    BotAccountDestroyError = Class.new(StandardError)
    attr_accessor :bot_account, :namespace

    def initialize(bot_account, namespace, user = nil)
      super(user)
      @bot_account = bot_account
      @namespace = namespace
    end

    def execute
      authorize! namespace, to: :destroy_bot_accounts?

      unless bot_account.email.downcase.include? @namespace.puid.downcase
        raise BotAccountDestroyError,
              I18n.t('services.bots.destroy.not_associated')
      end

      bot_account.destroy!
    rescue Bots::DestroyService::BotAccountDestroyError => e
      bot_account.errors.add(:base, e.message)
      false
    end
  end
end
