# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Bots
  # Component for rendering the PersonalAccessTokens tables
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop: disable Metrics/ParameterLists
    def initialize(
      bot_accounts,
      namespace,
      pagy,
      abilities: {},
      empty: {},
      **system_arguments
    )
      @bot_accounts = bot_accounts
      @namespace = namespace
      @pagy = pagy
      @abilities = abilities
      @empty = empty
      @system_arguments = system_arguments
    end
    # rubocop: enable Metrics/ParameterLists

    private

    def bot_tokens_path(bot)
      if @namespace.is_a?(Group)
        group_bot_personal_access_tokens_path(bot_id: bot.id)
      elsif @namespace.is_a?(Namespaces::ProjectNamespace)
        namespace_project_bot_personal_access_tokens_path(bot_id: bot.id)
      end
    end

    def new_token_path(bot)
      if @namespace.is_a?(Group)
        new_group_bot_personal_access_token_path(bot_id: bot.id)
      elsif @namespace.is_a?(Namespaces::ProjectNamespace)
        new_namespace_project_bot_personal_access_token_path(bot_id: bot.id)
      end
    end

    def destroy_path(bot)
      if @namespace.is_a?(Group)
        group_bot_path(id: bot.id)
      elsif @namespace.is_a?(Namespaces::ProjectNamespace)
        namespace_project_bot_path(id: bot.id)
      end
    end
  end
end
