# frozen_string_literal: true

module PersonalAccessTokens
  # Service used to create personal access tokens
  class CreateService < BaseService
    attr_accessor :namespace, :bot_user, :personal_access_token

    class PersonalAccessTokenCreateError < StandardError
    end

    def initialize(user, params, namespace = nil, bot_user = nil)
      super(user, params)

      @bot_user = bot_user
      @namespace = namespace
      @personal_access_token = PersonalAccessToken.new(params.merge(user: bot_user.nil? ? current_user : bot_user))
    end

    def execute
      validate_project_not_archived

      authorize! current_user, to: :generate_bot_personal_access_token? if bot_user.nil?
      authorize! namespace, to: :generate_bot_personal_access_token? unless bot_user.nil?

      personal_access_token.save

      personal_access_token
    rescue PersonalAccessTokens::CreateService::PersonalAccessTokenCreateError => e
      personal_access_token.errors.add(:base, e.message)
      personal_access_token
    end

    private

    def validate_project_not_archived
      return unless @namespace.instance_of?(Namespaces::ProjectNamespace) &&
                    @namespace.archived_at.present?

      raise PersonalAccessTokenCreateError,
            I18n.t('services.personal_access_tokens.create.project_read_only')
    end
  end
end
