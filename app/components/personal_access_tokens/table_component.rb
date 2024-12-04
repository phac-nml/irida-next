# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module PersonalAccessTokens
  # Component for rendering the PersonalAccessTokens tables
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    def initialize(
      personal_access_tokens,
      namespace: nil,
      bot_account: nil,
      empty: {},
      **system_arguments
    )
      @personal_access_tokens = personal_access_tokens
      @namespace = namespace
      @bot_account = bot_account
      @empty = empty
      @system_arguments = system_arguments
    end

    private

    def revoke_path(token)
      if @namespace.is_a?(Group)
        new_revoke_group_bot_personal_access_token_path(
          bot_id: @bot_account.id,
          id: token.id
        )
      elsif @namespace.is_a?(Namespaces::ProjectNamespace)
        new_revoke_namespace_project_bot_personal_access_token_path(
          bot_id: @bot_account.id,
          id: token.id
        )
      else
        revoke_profile_personal_access_token_path(id: token.id)
      end
    end

    def revoke_data_attributes
      if @namespace
        { 'turbo-stream': true }
      else
        {
          turbo_method: :delete,
          turbo_confirm: t('personal_access_tokens.table.revoke_confirmation')
        }
      end
    end
  end
end
