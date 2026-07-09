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

    def execute # rubocop:disable Metrics/AbcSize
      validate_project_not_archived(@namespace) if !bot_user.nil? && @namespace.project_namespace?

      authorize! current_user, to: :generate_bot_personal_access_token? if bot_user.nil?
      authorize! namespace, to: :generate_bot_personal_access_token? unless bot_user.nil?

      personal_access_token.save

      personal_access_token
    rescue PersonalAccessTokens::CreateService::PersonalAccessTokenCreateError => e
      personal_access_token.errors.add(:base, e.message)
      personal_access_token
    end
  end
end
