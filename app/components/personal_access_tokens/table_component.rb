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
      @revoked_pats = personal_access_tokens.any?(&:revoked?)
      @expired_pats = personal_access_tokens.any?(&:expired?)
      @system_arguments = system_arguments
      actions
    end

    private

    def revoke_path(token)
      if @namespace.is_a?(Group)
        revoke_confirmation_group_bot_personal_access_token_path(
          bot_id: @bot_account.id,
          id: token.id
        )
      elsif @namespace.is_a?(Namespaces::ProjectNamespace)
        revoke_confirmation_namespace_project_bot_personal_access_token_path(
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

    def revoke_http_method
      if @namespace
        :get
      else
        :delete
      end
    end

    def actions
      @actions = if @revoked_pats || @expired_pats
                   {}
                 else
                   { revoke: true }
                 end
    end

    def row_token_status(token)
      status = {}
      if token.active? && !token.expiring?
        status.merge!(color: :green, text: I18n.t('personal_access_tokens.table.status.active'))
      elsif token.expiring?
        status.merge!(color: :orange, text: I18n.t('personal_access_tokens.table.status.expiring'))
      elsif token.expired?
        status.merge!(color: :amber, text: I18n.t('personal_access_tokens.table.status.expired'))
      else
        status.merge!(color: :red, text: I18n.t('personal_access_tokens.table.status.revoked'))
      end

      status
    end

    def show_integration_host?
      Flipper.enabled?(:integration_access_token_generation)
    end
  end
end
