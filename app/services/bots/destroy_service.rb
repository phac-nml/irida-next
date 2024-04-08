# frozen_string_literal: true

module Bots
  # Service used to Delete Projects
  class DestroyService < BaseService
    attr_accessor :bot_account, :namespace

    def initialize(bot_account, namespace, user = nil)
      super(user)
      @bot_account = bot_account
      @namespace = namespace
    end

    def execute
      authorize! namespace, to: :destroy_bot_accounts?

      bot_account.destroy!
    end
  end
end
