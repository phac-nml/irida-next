# frozen_string_literal: true

require 'test_helper'

class BotActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:john_doe)
    @namespace = groups(:group_one)
    @project = projects(:project1)
    @project_bot = namespace_bots(:project1_bot0)
    @group_bot = namespace_bots(:group1_bot0)
  end

  test 'project bot accounts index' do
    get namespace_project_bots_path(@namespace, @project)

    assert_response :success

    w3c_validate 'Project Bot Accounts Page'
  end

  test 'new project bot account' do
    get new_namespace_project_bot_path(@namespace, @project, format: :turbo_stream)

    assert_response :success
  end

  test 'project bot account create' do
    post namespace_project_bots_path(@namespace, @project, format: :turbo_stream),
         params: { bot: {
           token_name: 'newtesttoken',
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_response :success
  end

  test 'project bot account create error' do
    post namespace_project_bots_path(@namespace, @project, format: :turbo_stream),
         params: { bot: {
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_response :unprocessable_entity
  end

  test 'project bot account destroy' do
    delete namespace_project_bot_path(@namespace, @project, id: @project_bot.id, format: :turbo_stream)

    assert_response :redirect
  end

  test 'project bot account destroy error' do
    project2 = projects(:project2)

    delete namespace_project_bot_path(@namespace, project2, id: 0, format: :turbo_stream)

    assert_response :not_found
  end

  test 'group bot accounts index' do
    get group_bots_path(@namespace)

    assert_response :success

    w3c_validate 'Group Bot Accounts Page'
  end

  test 'new group bot account' do
    get new_group_bot_path(@namespace, format: :turbo_stream)

    assert_response :success
  end

  test 'group bot account create' do
    post group_bots_path(@namespace, format: :turbo_stream),
         params: { bot: {
           token_name: 'newtesttoken',
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_response :success
  end

  test 'group bot account create error' do
    post group_bots_path(@namespace, format: :turbo_stream),
         params: { bot: {
           access_level: Member::AccessLevel::UPLOADER,
           scopes: ['read_api']
         } }

    assert_response :unprocessable_entity
  end

  test 'group bot account destroy' do
    delete group_bot_path(@namespace, id: @group_bot.id, format: :turbo_stream)

    assert_response :redirect
  end

  test 'group bot account destroy error' do
    delete group_bot_path(@namespace, id: 0, format: :turbo_stream)

    assert_response :not_found
  end

  test 'destroy_confirmation in group' do
    get group_bot_destroy_confirmation_path(@namespace, bot_id: @group_bot.id)

    assert_response :success
  end

  test 'unauthorized destroy_confirmation in group' do
    sign_in users(:ryan_doe)

    get group_bot_destroy_confirmation_path(@namespace, bot_id: @group_bot.id)

    assert_response :unauthorized
  end

  test 'destroy_confirmation in project' do
    get namespace_project_bot_destroy_confirmation_path(@namespace, @project, bot_id: @project_bot.id)

    assert_response :success
  end

  test 'unauthorized destroy_confirmation in project' do
    sign_in users(:ryan_doe)

    get namespace_project_bot_destroy_confirmation_path(@namespace, @project, bot_id: @project_bot.id)

    assert_response :unauthorized
  end
end
