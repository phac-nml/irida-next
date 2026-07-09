# frozen_string_literal: true

module Bots
  # Service used to Delete Projects
  class DestroyService < BaseService
    attr_accessor :namespace_bot

    class BotsDestroyError < StandardError
    end

    def initialize(namespace_bot = nil, user = nil, params = {})
      super(user, params)
      @namespace_bot = namespace_bot
    end

    def execute
      validate_project_not_archived(@namespace_bot.namespace) if @namespace_bot.namespace.project_namespace?

      authorize! namespace_bot.namespace, to: :destroy_bot_accounts?

      namespace_bot.destroy
    rescue Bots::DestroyService::BotsDestroyError => e
      @namespace_bot.errors.add(:base, e.message)
      @namespace_bot
    end
  end
end
