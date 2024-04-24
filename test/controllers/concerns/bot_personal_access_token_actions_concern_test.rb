# frozen_string_literal: true

require 'test_helper'

class BotPersonalAcessTokenActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'bot personal access tokens index' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    get namespace_project_bot_personal_access_tokens_path(namespace, project, bot_id: namespace_bot.id,
                                                                              format: :turbo_stream)

    assert_response :success
  end

  test 'bot personal access tokens index not accessible for user with incorrect permissions' do
    sign_in users(:micha_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    get namespace_project_bot_personal_access_tokens_path(namespace, project, bot_id: namespace_bot.id,
                                                                              format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'new bot personal access token' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    get new_namespace_project_bot_personal_access_token_path(namespace, project, bot_id: namespace_bot.id,
                                                                                 format: :turbo_stream)

    assert_response :success
  end

  test 'bot personal access tokens new not accessible for user with incorrect permissions' do
    sign_in users(:micha_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    get new_namespace_project_bot_personal_access_token_path(namespace, project, bot_id: namespace_bot.id,
                                                                                 format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'bot create personal access token' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    post namespace_project_bot_personal_access_tokens_path(namespace, project, bot_id: namespace_bot.id,
                                                                               format: :turbo_stream),
         params: { personal_access_token: {
           name: 'Newest Token', scopes: %w[read_api api]
         } }

    assert_response :success
  end

  test 'cannot create bot personal access tokens for user with incorrect permissions' do
    sign_in users(:micha_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    post namespace_project_bot_personal_access_tokens_path(namespace, project, bot_id: namespace_bot.id,
                                                                               format: :turbo_stream),
         params: { personal_access_token: {
           name: 'Newest Token', scopes: %w[read_api api]
         } }

    assert_response :unauthorized
  end

  test 'cannot create bot personal access token with missing token name' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    post namespace_project_bot_personal_access_tokens_path(namespace, project, bot_id: namespace_bot.id,
                                                                               format: :turbo_stream),
         params: { personal_access_token: {
           scopes: %w[read_api api]
         } }

    assert_response :unprocessable_entity
  end

  test 'cannot create bot personal access token with missing scopes' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot0)

    post namespace_project_bot_personal_access_tokens_path(namespace, project, bot_id: namespace_bot.id,
                                                                               format: :turbo_stream),
         params: { personal_access_token: {
           name: 'Newest Token'
         } }

    assert_response :unprocessable_entity
  end
end
