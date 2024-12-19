# frozen_string_literal: true

require 'test_helper'

module Groups
  class BotsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should successfully get bot accounts listing page' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)

      get group_bots_path(namespace)

      assert_response :success
    end

    test 'should not get bot accounts listing page for a user with incorrect permissions' do
      sign_in users(:micha_doe)

      namespace = groups(:group_one)

      get group_bots_path(namespace)

      assert_response :unauthorized
    end

    test 'should successfully get the new bot account modal' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)

      get new_group_bot_path(namespace, format: :turbo_stream)

      assert_response :success
    end

    test 'should not get the new bot account modal for a user with incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace = groups(:group_one)

      get new_group_bot_path(namespace, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'should successfully create a new bot account' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)

      post group_bots_path(namespace, format: :turbo_stream),
           params: { bot: {
             token_name: 'newtesttoken',
             access_level: Member::AccessLevel::UPLOADER,
             scopes: ['read_api']
           } }

      assert_response :success
    end

    test 'should not create a new bot account for a user with incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace = groups(:group_one)

      post group_bots_path(namespace, format: :turbo_stream),
           params: { bot: {
             token_name: 'newtesttoken',
             access_level: Member::AccessLevel::UPLOADER,
             scopes: ['read_api']
           } }

      assert_response :unauthorized
    end

    test 'should successfully destroy a bot account' do
      sign_in users(:john_doe)

      namespace_bot = namespace_bots(:group1_bot0)

      namespace = groups(:group_one)

      delete group_bot_path(namespace, id: namespace_bot.id, format: :turbo_stream)

      assert_response :redirect
    end

    test 'should not destroy a bot account for a bot account that does not belong to the project' do
      sign_in users(:john_doe)

      namespace_bot = namespace_bots(:group1_bot0)

      namespace = groups(:group_two)

      delete group_bot_path(namespace, id: namespace_bot.id, format: :turbo_stream)

      assert_response :not_found
    end

    test 'should not destroy a bot account for a user with incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace_bot = namespace_bots(:group1_bot0)

      namespace = groups(:group_one)

      delete group_bot_path(namespace, id: namespace_bot.id, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'response should be not found when trying to destroy a bot account with a non-existent id' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)

      delete group_bot_path(namespace, id: 0, format: :turbo_stream)

      assert_response :not_found
    end
  end
end
