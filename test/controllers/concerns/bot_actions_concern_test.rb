# frozen_string_literal: true

require 'test_helper'

class BotActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'project bot accounts index' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    get namespace_project_bots_path(namespace, project)

    assert_response :success
  end

  test 'new project bot account' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    get new_namespace_project_bot_path(namespace, project, format: :turbo_stream)

    assert_response :success
  end

  test 'project bot account create' do
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

  test 'project bot account create error' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    post namespace_project_bots_path(namespace, project, format: :turbo_stream),
         params: { bot: {
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_response :unprocessable_entity
  end

  test 'project bot account destroy' do
    sign_in users(:john_doe)

    namespace_bot = namespace_bots(:project1_bot0)

    namespace = groups(:group_one)
    project = projects(:project1)

    delete namespace_project_bot_path(namespace, project, id: namespace_bot.id, format: :turbo_stream)

    assert_response :redirect
  end

  test 'project bot account destroy error' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project2)

    delete namespace_project_bot_path(namespace, project, id: 0, format: :turbo_stream)

    assert_response :not_found
  end

  test 'group bot accounts index' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)

    get group_bots_path(namespace)

    assert_response :success
  end

  test 'new group bot account' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)

    get new_group_bot_path(namespace, format: :turbo_stream)

    assert_response :success
  end

  test 'group bot account create' do
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

  test 'group bot account create error' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)

    post group_bots_path(namespace, format: :turbo_stream),
         params: { bot: {
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_response :unprocessable_entity
  end

  test 'group bot account destroy' do
    sign_in users(:john_doe)

    namespace_bot = namespace_bots(:group1_bot0)

    namespace = groups(:group_one)

    delete group_bot_path(namespace, id: namespace_bot.id, format: :turbo_stream)

    assert_response :redirect
  end

  test 'group bot account destroy error' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)

    delete group_bot_path(namespace, id: 0, format: :turbo_stream)

    assert_response :not_found
  end

  test 'new_destroy in group' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    namespace_bot = namespace_bots(:group1_bot0)

    get group_bot_new_destroy_path(namespace, bot_id: namespace_bot.id)

    assert_response :success
  end

  test 'new_destroy in project' do
    sign_in users(:john_doe)

    namespace_bot = namespace_bots(:project1_bot0)

    namespace = groups(:group_one)
    project = projects(:project1)

    get namespace_project_bot_new_destroy_path(namespace, project, bot_id: namespace_bot.id)

    assert_response :success
  end
end
