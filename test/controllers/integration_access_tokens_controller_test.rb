# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class IntegrationAccessTokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    Flipper.enable(:integration_access_token_generation)
  end

  test 'should get index' do
    sign_in users(:john_doe)

    get integration_access_token_index_path
    assert_response :success

    w3c_validate 'Integration Access Tokens Page'
  end

  test 'should create integration access token' do
    sign_in users(:john_doe)

    assert_difference(-> { users(:john_doe).personal_access_tokens.count } => 1) do
      post integration_access_token_index_path(format: :turbo_stream), headers: { 'HTTP_REFERER' => 'http://localhost:3000/integration_access_token?caller=test_integration_identifier' }
    end

    assert_response :success

    token = users(:john_doe).personal_access_tokens.last
    assert_equal ['api'], token.scopes
    assert_equal users(:john_doe).id, token.user_id
    assert token.integration
    assert_equal 'test_integration_identifier', token.integration_host
  end

  test 'should not create integration access token when caller is not allowed' do
    sign_in users(:john_doe)

    assert_no_difference(-> { users(:john_doe).personal_access_tokens.count }) do
      post integration_access_token_index_path(format: :turbo_stream), headers: { 'HTTP_REFERER' => 'http://localhost:3000/integration_access_token?caller=not_a_valid_identifier' }
    end

    assert_response :unprocessable_content
  end
end
