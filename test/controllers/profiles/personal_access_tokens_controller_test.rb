# frozen_string_literal: true

require 'test_helper'

module Profiles
  class PersonalAccessTokensControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get index' do
      sign_in users(:john_doe)

      get profile_personal_access_tokens_path
      assert_response :success

      w3c_validate 'User Profile Personal Access Tokens Page'
    end

    test 'should create personal access token' do
      sign_in users(:john_doe)

      assert_difference(-> { users(:john_doe).personal_access_tokens.count } => 1) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'token', scopes: ['api'] } }
      end

      assert_response :success
    end

    test 'should not create personal access token without scopes' do
      sign_in users(:john_doe)

      assert_no_difference(-> { users(:john_doe).personal_access_tokens.count }) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'token' } }
      end

      assert_response :unprocessable_entity
    end

    test 'should not create personal access token with invalid scopes' do
      sign_in users(:john_doe)

      assert_no_difference(-> { users(:john_doe).personal_access_tokens.count }) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'token', scopes: ['write_api'] } }
      end

      assert_response :unprocessable_entity
    end

    test 'should revoke personal access token' do
      sign_in users(:john_doe)

      assert_difference(-> { users(:john_doe).personal_access_tokens.active.count } => -1) do
        delete revoke_profile_personal_access_token_path(id: personal_access_tokens(:john_doe_valid_pat),
                                                         format: :turbo_stream)
      end

      assert_response :success
    end

    test 'should not revoke personal access token for another user' do
      sign_in users(:john_doe)

      delete revoke_profile_personal_access_token_path(id: personal_access_tokens(:jane_doe_valid_pat),
                                                       format: :turbo_stream)
      assert_response :not_found
    end

    test 'should not revoke personal access token which doesn\'t exist' do
      sign_in users(:john_doe)

      assert_no_difference -> { users(:john_doe).personal_access_tokens.active.count } do
        delete revoke_profile_personal_access_token_path(id: 'not-a-read-id',
                                                         format: :turbo_stream)
      end

      assert_response :not_found
    end
  end
end
