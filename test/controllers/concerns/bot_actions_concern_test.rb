# frozen_string_literal: true

require 'test_helper'

class BotActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'bot accounts index' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    get namespace_project_bots_path(namespace, project, format: :turbo_stream)

    assert_response :success
  end

  test 'new bot account' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    get new_namespace_project_bot_path(namespace, project, format: :turbo_stream)

    assert_response :success
  end

  test 'bot account create' do
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

  test 'bot account create error' do
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

  test 'bot account destroy' do
    sign_in users(:john_doe)

    namespace_bot = namespace_bots(:project1_bot)

    namespace = groups(:group_one)
    project = projects(:project1)

    delete namespace_project_bot_path(namespace, project, id: namespace_bot.id, format: :turbo_stream)

    assert_response :success
  end

  test 'bot account destroy error' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project2)

    delete namespace_project_bot_path(namespace, project, id: 0, format: :turbo_stream)

    assert_response :not_found
  end

  test 'generate new personal access token for bot account' do
    sign_in users(:john_doe)

    namespace_bot = namespace_bots(:project1_bot)

    namespace = groups(:group_one)
    project = projects(:project1)

    assert_equal 1, namespace_bot.user.personal_access_tokens.count

    post generate_personal_access_token_namespace_project_bot_path(namespace, project, id: namespace_bot.id,
                                                                                       format: :turbo_stream),
         params: { bot: {
           token_name: 'newtesttoken',
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_equal 2,
                 namespace_bot.user.personal_access_tokens.count

    assert_response :success
  end
end
