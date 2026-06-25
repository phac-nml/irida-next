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
      validate_project_not_archived

      authorize! namespace_bot.namespace, to: :destroy_bot_accounts?

      namespace_bot.destroy
    rescue Bots::DestroyService::BotsDestroyError => e
      @namespace_bot.errors.add(:base, e.message)
      @namespace_bot
    end

    private

    def validate_project_not_archived
      return unless @namespace_bot.namespace.instance_of?(Namespaces::ProjectNamespace) &&
                    @namespace_bot.namespace.archived_at.present?

      raise BotsDestroyError,
            I18n.t('services.bots.destroy.project_read_only')
    end
  end
end
