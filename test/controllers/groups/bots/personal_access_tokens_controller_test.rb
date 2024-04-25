# frozen_string_literal: true

require 'test_helper'

module Groups
  module Bots
    class PersonalAccessTokensControllerTest < ActionDispatch::IntegrationTest
      include Devise::Test::IntegrationHelpers

      test 'should successfully get bot personal access tokens listing' do
        sign_in users(:john_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        get group_bot_personal_access_tokens_path(namespace, bot_id: namespace_bot.id,
                                                             format: :turbo_stream)

        assert_response :success
      end

      test 'should not successfully get bot personal access tokens listing for user with incorrect permissions' do
        sign_in users(:micha_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        get group_bot_personal_access_tokens_path(namespace, bot_id: namespace_bot.id,
                                                             format: :turbo_stream)

        assert_response :unauthorized
      end

      test 'should successfully get the new bot personal access token modal' do
        sign_in users(:john_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        get new_group_bot_personal_access_token_path(namespace, bot_id: namespace_bot.id,
                                                                format: :turbo_stream)

        assert_response :success
      end

      test 'should not successfully get the new bot personal access token modal for user with incorrect permissions' do
        sign_in users(:micha_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        get new_group_bot_personal_access_token_path(namespace, bot_id: namespace_bot.id,
                                                                format: :turbo_stream)

        assert_response :unauthorized
      end

      test 'should successfully create a new bot personal access token' do
        sign_in users(:john_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        post group_bot_personal_access_tokens_path(namespace, bot_id: namespace_bot.id,
                                                              format: :turbo_stream),
             params: { personal_access_token: {
               name: 'Newest Token', scopes: %w[read_api api]
             } }

        assert_response :success
      end

      test 'should not successfully create a new bot personal access token for user with incorrect permissions' do
        sign_in users(:micha_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        post group_bot_personal_access_tokens_path(namespace, bot_id: namespace_bot.id,
                                                              format: :turbo_stream),
             params: { personal_access_token: {
               name: 'Newest Token', scopes: %w[read_api api]
             } }

        assert_response :unauthorized
      end

      test 'should not successfully create a new bot personal access token with missing token name' do
        sign_in users(:john_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        post group_bot_personal_access_tokens_path(namespace, bot_id: namespace_bot.id,
                                                              format: :turbo_stream),
             params: { personal_access_token: {
               scopes: %w[read_api api]
             } }

        assert_response :unprocessable_entity
      end

      test 'should not successfully create a new bot personal access token with missing scopes' do
        sign_in users(:john_doe)

        namespace = groups(:group_one)

        namespace_bot = namespace_bots(:group1_bot0)

        post group_bot_personal_access_tokens_path(namespace, bot_id: namespace_bot.id,
                                                              format: :turbo_stream),
             params: { personal_access_token: {
               name: 'Newest Token'
             } }

        assert_response :unprocessable_entity
      end
    end
  end
end
