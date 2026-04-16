# frozen_string_literal: true

module PersonalAccessTokens
  # Service used to rotate personal access tokens
  class RotateService < BaseService
    class RotateError < StandardError
    end

    attr_accessor :existing_personal_access_token, :namespace, :bot_user

    def initialize(user, existing_personal_access_token, namespace = nil, bot_user = nil)
      super(user)

      @existing_personal_access_token = existing_personal_access_token
      @namespace = namespace
      @bot_user = bot_user
    end

    def execute
      authorize! @existing_personal_access_token.user, to: :rotate_personal_access_token? if bot_user.nil?
      authorize! namespace, to: :rotate_bot_personal_access_token? unless bot_user.nil?

      validate_existing_token

      @existing_personal_access_token.revoke!

      @new_personal_access_token = copy_token_attributes
      @new_personal_access_token.save

      @new_personal_access_token
    rescue PersonalAccessTokens::RotateService::RotateError => e
      @existing_personal_access_token.errors.add(:base, e.message)
      @existing_personal_access_token
    end

    private

    def validate_existing_token
      return if @existing_personal_access_token.active?

      raise RotateError, I18n.t('activerecord.errors.models.personal_access_tokens.rotate.only_active')
    end

    def copy_token_attributes
      @existing_personal_access_token.dup.tap do |token|
        token.token_digest = nil
        token.last_used_at = nil
        token.revoked = false
      end
    end
  end
end
