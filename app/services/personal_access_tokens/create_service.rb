# frozen_string_literal: true

module PersonalAccessTokens
  # Service used to create personal access tokens
  class CreateService < BaseService
    attr_accessor :namespace, :bot_user, :personal_access_token

    def initialize(user, params, namespace = nil, bot_user = nil)
      super(user, params)

      @bot_user = bot_user
      @namespace = namespace
      @personal_access_token = PersonalAccessToken.new(params.merge(user: bot_user.nil? ? current_user : bot_user))
    end

    def execute
      authorize! current_user, to: :generate_bot_personal_access_token? if bot_user.nil?
      authorize! namespace, to: :generate_bot_personal_access_token? unless bot_user.nil?

      personal_access_token.save

      personal_access_token
    end
  end
end
