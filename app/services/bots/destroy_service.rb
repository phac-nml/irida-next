# frozen_string_literal: true

module Bots
  # Service used to Delete Projects
  class DestroyService < BaseService
    attr_accessor :namespace_bot

    def initialize(namespace_bot = nil, user = nil, params = {})
      super(user, params)
      @namespace_bot = namespace_bot
    end

    def execute
      authorize! namespace_bot.namespace, to: :destroy_bot_accounts?

      namespace_bot.destroy
    end
  end
end
