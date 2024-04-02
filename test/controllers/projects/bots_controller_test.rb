# frozen_string_literal: true

require 'test_helper'

module Projects
  class BotsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should successfully get bot accounts listing page' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      get namespace_project_bots_path(namespace, project, format: :turbo_stream)

      assert_response :success
    end

    test 'should not get bot accounts listing page for a user with incorrect permissions' do
      sign_in users(:micha_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      get namespace_project_bots_path(namespace, project, format: :turbo_stream)

      assert_response :success
    end

    test 'should successfully get the new bot account modal' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      get new_namespace_project_bot_path(namespace, project, format: :turbo_stream)

      assert_response :success
    end

    test 'should not get the new bot account modal for a user with incorrect permissions' do
      sign_in users(:ryan_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      get new_namespace_project_bot_path(namespace, project, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'should successfully create a new bot account' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      post namespace_project_bots_path(namespace, project, format: :turbo_stream),
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
      project = projects(:project1)

      post namespace_project_bots_path(namespace, project, format: :turbo_stream),
           params: { bot: {
             token_name: 'newtesttoken',
             access_level: Member::AccessLevel::UPLOADER,
             scopes: ['read_api']
           } }

      assert_response :unauthorized
    end

    test 'should successfully destroy a bot account' do
      sign_in users(:john_doe)

      bot_account = users(:user_bot_account0)

      namespace = groups(:group_one)
      project = projects(:project1)

      delete namespace_project_bot_path(namespace, project, id: bot_account.namespace.id, format: :turbo_stream)

      assert_response :success
    end

    test 'should not destroy a bot account for a bot account that does not belong to the project' do
      sign_in users(:john_doe)

      bot_account = users(:user_bot_account0)

      namespace = groups(:group_one)
      project = projects(:project2)

      delete namespace_project_bot_path(namespace, project, id: bot_account.namespace.id, format: :turbo_stream)

      assert_response :unprocessable_entity
    end

    test 'should not destroy a bot account for a user with incorrect permissions' do
      sign_in users(:ryan_doe)

      bot_account = users(:user_bot_account0)

      namespace = groups(:group_one)
      project = projects(:project1)

      delete namespace_project_bot_path(namespace, project, id: bot_account.namespace.id, format: :turbo_stream)

      assert_response :unauthorized
    end
  end
end
