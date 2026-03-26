# frozen_string_literal: true

require 'test_helper'

module Profiles
  class PersonalAccessTokensControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:john_doe)
      sign_in @user
    end

    test 'should get index' do
      get profile_personal_access_tokens_path
      assert_response :success

      w3c_validate 'User Profile Personal Access Tokens Page'
    end

    test 'should create personal access token' do
      assert_difference(-> { @user.personal_access_tokens.count } => 1) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'token', scopes: ['api'] } }
      end

      assert_response :success
    end

    test 'should not create personal access token without scopes' do
      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'token' } }
      end

      assert_response :unprocessable_content
    end

    test 'should not create personal access token with invalid scopes' do
      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'token', scopes: ['write_api'] } }
      end

      assert_response :unprocessable_content
    end

    test 'should revoke personal access token' do
      assert_difference(-> { @user.personal_access_tokens.active.count } => -1) do
        delete revoke_profile_personal_access_token_path(id: personal_access_tokens(:john_doe_valid_pat),
                                                         format: :turbo_stream)
      end

      assert_response :success
    end

    test 'should not revoke personal access token for another user' do
      delete revoke_profile_personal_access_token_path(id: personal_access_tokens(:jane_doe_valid_pat),
                                                       format: :turbo_stream)
      assert_response :not_found
    end

    test 'should not revoke personal access token which doesn\'t exist' do
      assert_no_difference -> { @user.personal_access_tokens.active.count } do
        delete revoke_profile_personal_access_token_path(id: 'not-a-read-id',
                                                         format: :turbo_stream)
      end

      assert_response :not_found
    end

    test 'should rotate personal access token' do
      personal_access_token = personal_access_tokens(:john_doe_valid_pat)
      assert_difference(-> { @user.personal_access_tokens.count } => 1) do
        assert_changes -> { personal_access_token.reload.revoked? } do
          put rotate_profile_personal_access_token_path(id: personal_access_token,
                                                        format: :turbo_stream)
        end
      end

      assert_response :success
    end

    test 'should not rotate personal access token for another user' do
      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        put rotate_profile_personal_access_token_path(id: personal_access_tokens(:jane_doe_valid_pat),
                                                      format: :turbo_stream)
      end
      assert_response :not_found
    end

    test 'should not rotate expired personal access token' do
      expired_pat = personal_access_tokens(:john_doe_expired_pat)

      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        assert_no_changes -> { expired_pat.reload.revoked? } do
          put rotate_profile_personal_access_token_path(id: expired_pat,
                                                        format: :turbo_stream)
        end
      end

      assert_response :unprocessable_entity
    end

    test 'should not rotate revoked personal access token' do
      revoked_pat = personal_access_tokens(:john_doe_revoked_pat)

      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        assert_no_changes -> { revoked_pat.reload.revoked } do
          put rotate_profile_personal_access_token_path(id: revoked_pat,
                                                        format: :turbo_stream)
        end
      end

      assert_response :unprocessable_entity
    end
  end
end
