# frozen_string_literal: true

require 'test_helper'

class BotPersonalAcessTokenActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'bot personal access tokens index' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot)

    get namespace_project_bot_personal_access_tokens_path(namespace, project, id: namespace_bot.id,
                                                                              format: :turbo_stream)

    assert_response :success
  end

  test 'new bot personal access token' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot)

    get new_namespace_project_bot_personal_access_token_path(namespace, project, id: namespace_bot.id,
                                                                                 format: :turbo_stream)

    assert_response :success
  end

  test 'bot create personal access token' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)

    namespace_bot = namespace_bots(:project1_bot)

    post namespace_project_bot_personal_access_tokens_path(namespace, project, id: namespace_bot.id,
                                                                               format: :turbo_stream),
         params: { personal_access_token: {
           name: 'Newest Token', scopes: %w[read_api api]
         } }

    assert_response :success
  end
end
