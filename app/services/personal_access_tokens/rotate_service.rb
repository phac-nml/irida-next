# frozen_string_literal: true

module PersonalAccessTokens
  # Service used to rotate personal access tokens
  class RotateService < BaseService
    class RotateError < StandardError
    end

    attr_accessor :existing_personal_access_token

    def initialize(user, existing_personal_access_token)
      super(user)

      @existing_personal_access_token = existing_personal_access_token
    end

    def execute
      authorize! @existing_personal_access_token.user, to: :rotate_personal_access_token?

      new_token_params = { name: @existing_personal_access_token.name,
                           expires_at: @existing_personal_access_token.expires_at,
                           scopes: @existing_personal_access_token.scopes }

      unless @existing_personal_access_token.active?
        raise RotateError, I18n.t('activerecord.errors.models.personal_access_tokens.rotate.only_active')
      end

      @existing_personal_access_token.revoke!
      @new_personal_access_token = PersonalAccessToken.new(new_token_params.merge(user: current_user))

      @new_personal_access_token.save

      @new_personal_access_token
    rescue PersonalAccessTokens::RotateService::RotateError => e
      @existing_personal_access_token.errors.add(:base, e.message)
      @existing_personal_access_token
    end
  end
end
