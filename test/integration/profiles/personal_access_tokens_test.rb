# frozen_string_literal: true

require 'test_helper'

class PersonalAccessTokensTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get index' do
    get profile_personal_access_tokens_path

    assert_response :success
  end

  test 'should get new' do
    get new_profile_personal_access_token_path(format: :turbo_stream)

    assert_response :success
  end

  test 'should list expired personal access tokens' do
    get list_profile_personal_access_tokens_path(type: :expired, format: :turbo_stream)

    assert_response :success
    assert_includes response.body, personal_access_tokens(:john_doe_expired_pat).name
  end

  test 'should list personal access tokens for every token status' do
    token_by_type = {
      active: personal_access_tokens(:john_doe_non_expirable_pat),
      expired: personal_access_tokens(:john_doe_expired_pat),
      revoked: personal_access_tokens(:john_doe_revoked_pat),
      expiring: personal_access_tokens(:john_doe_valid_pat)
    }

    token_by_type.each do |type, token|
      get list_profile_personal_access_tokens_path(type:, format: :turbo_stream)

      assert_response :success
      assert_includes response.body, "personal_access_token_#{token.id}"
    end
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

  test 'should display base errors when personal access token creation fails' do
    token_with_errors = PersonalAccessToken.new
    token_with_errors.errors.add(:base, 'Creation failed')
    create_service = mock('create_service')
    create_service.stubs(:execute).returns(token_with_errors)
    PersonalAccessTokens::CreateService.expects(:new).returns(create_service)
    Profiles::PersonalAccessTokensController.any_instance.expects(:error_message)
                                            .with(token_with_errors).returns('Creation failed')

    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      post profile_personal_access_tokens_path(format: :turbo_stream),
           params: { personal_access_token: { name: 'token', scopes: ['api'] } }
    end

    assert_response :unprocessable_content
  end

  test 'should revoke personal access token' do
    token = personal_access_tokens(:john_doe_valid_pat)

    assert_changes -> { token.reload.revoked? }, from: false, to: true do
      delete revoke_profile_personal_access_token_path(id: token, format: :turbo_stream)
    end

    assert_response :success
  end

  test 'should not revoke personal access token for another user' do
    assert_no_changes -> { personal_access_tokens(:jane_doe_valid_pat).reload.revoked? } do
      delete revoke_profile_personal_access_token_path(id: personal_access_tokens(:jane_doe_valid_pat),
                                                       format: :turbo_stream)
    end

    assert_response :not_found
  end

  test 'should rotate personal access token' do
    token = personal_access_tokens(:john_doe_valid_pat)

    assert_difference(-> { @user.personal_access_tokens.count } => 1) do
      assert_changes -> { token.reload.revoked? }, from: false, to: true do
        put rotate_profile_personal_access_token_path(id: token, format: :turbo_stream)
      end
    end

    assert_response :success
  end

  test 'should not rotate expired personal access token' do
    token = personal_access_tokens(:john_doe_expired_pat)

    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      assert_no_changes -> { token.reload.revoked? } do
        put rotate_profile_personal_access_token_path(id: token, format: :turbo_stream)
      end
    end

    assert_response :unprocessable_entity
  end

  test 'should not rotate revoked personal access token' do
    token = personal_access_tokens(:john_doe_revoked_pat)

    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      assert_no_changes -> { token.reload.revoked? } do
        put rotate_profile_personal_access_token_path(id: token, format: :turbo_stream)
      end
    end

    assert_response :unprocessable_entity
  end
end
