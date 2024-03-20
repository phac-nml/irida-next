# frozen_string_literal: true

module Bots
  # Service used to Create Bot Accounts
  class CreateService < BaseService
    BotAccountCreateError = Class.new(StandardError)

    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
    rescue Bots::CreateService::BotAccountCreateError => e
      false
    end
  end
end
