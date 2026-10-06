# frozen_string_literal: true

require 'test_helper'

class SessionlessAuthController < ApplicationController
  include SessionlessAuthentication

  skip_before_action :authenticate_user!

  protect_from_forgery with: :null_session, only: :execute

  before_action { authenticate_sessionless_user! }

  def fake_action
    render json: { current_user: { email: current_user&.email } }
  end
end

class SessionlessAuthenticationConcernTest < ActionDispatch::IntegrationTest
  test 'request without HTTP Basic Authorization header does not set current_user' do
    with_routing do |set|
      set.draw do
        post 'fake_action' => 'sessionless_auth#fake_action'
      end

      post '/fake_action'
      assert_response :success
      response_hash = response.parsed_body

      assert response_hash.key?('current_user')
      assert response_hash['current_user'].key?('email')
      assert_nil response_hash['current_user']['email']
    end
  end

  test 'request with valid HTTP Basic Authorization header sets current_user' do
    basic_auth = Base64.encode64("#{users(:john_doe).email}:JQ2w5maQc4zgvC8GGMEp")
    authorization_header = "Basic #{basic_auth}"

    with_routing do |set|
      set.draw do
        post 'fake_action' => 'sessionless_auth#fake_action'
      end

      post '/fake_action', headers: { Authorization: authorization_header }
      assert_response :success
      response_hash = response.parsed_body

      assert response_hash.key?('current_user')
      assert response_hash['current_user'].key?('email')
      assert_equal users(:john_doe).email, response_hash['current_user']['email']
    end
  end

  test 'request with invalid HTTP Basic Authorization header does not set current_user' do
    basic_auth = Base64.encode64("#{users(:jane_doe).email}:JQ2w5maQc4zgvC8GGMEp")
    authorization_header = "Basic #{basic_auth}"

    with_routing do |set|
      set.draw do
        post 'fake_action' => 'sessionless_auth#fake_action'
      end

      post '/fake_action', headers: { Authorization: authorization_header }
      assert_response :success
      response_hash = response.parsed_body

      assert response_hash.key?('current_user')
      assert response_hash['current_user'].key?('email')
      assert_not_equal users(:john_doe).email, response_hash['current_user']['email']
    end
  end

  test 'request with malformed HTTP Basic Authorization header does not set current_user' do
    basic_auth = Base64.encode64('MALFORMED')
    authorization_header = "Basic #{basic_auth}"

    with_routing do |set|
      set.draw do
        post 'fake_action' => 'sessionless_auth#fake_action'
      end

      post '/fake_action', headers: { Authorization: authorization_header }
      assert_response :success
      response_hash = response.parsed_body

      assert response_hash.key?('current_user')
      assert response_hash['current_user'].key?('email')
      assert_nil response_hash['current_user']['email']
    end
  end
end
