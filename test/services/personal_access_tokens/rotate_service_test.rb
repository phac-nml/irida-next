# frozen_string_literal: true

require 'test_helper'

module PersonalAccessTokens
  class RotateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'rotate personal access token for user' do
      personal_access_token = personal_access_tokens(:john_doe_valid_pat)
      assert_difference(-> { @user.personal_access_tokens.count } => 1) do
        assert_changes -> { personal_access_token.reload.revoked? } do
          new_token = PersonalAccessTokens::RotateService.new(@user, personal_access_token).execute

          assert_not_equal new_token, personal_access_token
          assert_not_equal new_token.token_digest, personal_access_token.token_digest
          assert_not_equal new_token.created_at, personal_access_token.created_at
          assert_equal new_token.name, personal_access_token.name
          assert_equal new_token.expires_at, personal_access_token.expires_at
          assert_equal new_token.scopes, personal_access_token.scopes
        end
      end
    end

    test 'should not rotate personal access token for another user' do
      user = users(:jane_doe)
      jane_doe_personal_access_token = personal_access_tokens(:jane_doe_valid_pat)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        PersonalAccessTokens::RotateService.new(@user, jane_doe_personal_access_token).execute
      end

      assert_equal UserPolicy, exception.policy
      assert_equal :rotate_personal_access_token?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)

      assert_equal I18n.t(:'action_policy.policy.user.rotate_personal_access_token?',
                          name: user.email),
                   exception.result.message
    end

    test 'should not rotate expired personal access token' do
      expired_pat = personal_access_tokens(:john_doe_expired_pat)

      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        assert_no_changes -> { expired_pat.reload.revoked? } do
          pat = PersonalAccessTokens::RotateService.new(@user, expired_pat).execute
          assert pat.errors.full_messages.include?(
            I18n.t('activerecord.errors.models.personal_access_tokens.rotate.only_active')
          )
        end
      end
    end

    test 'should not rotate revoked personal access token' do
      revoked_pat = personal_access_tokens(:john_doe_revoked_pat)

      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        assert_no_changes -> { revoked_pat.reload.revoked? } do
          pat = PersonalAccessTokens::RotateService.new(@user, revoked_pat).execute
          assert pat.errors.full_messages.include?(
            I18n.t('activerecord.errors.models.personal_access_tokens.rotate.only_active')
          )
        end
      end
    end
  end
end
