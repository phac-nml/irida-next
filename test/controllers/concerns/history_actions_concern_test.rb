# frozen_string_literal: true

require 'test_helper'

class HistoryActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'project history index' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)
    project.namespace.create_logidze_snapshot!

    get namespace_project_history_path(namespace, project)

    assert_response :success

    w3c_validate 'Project History Page'
  end

  test 'view project history version' do
    sign_in users(:john_doe)

    namespace = groups(:group_one)
    project = projects(:project1)
    project.namespace.create_logidze_snapshot!

    get namespace_project_view_history_path(namespace, project, version: 1, format: :turbo_stream)

    assert_response :success
  end

  test 'group history index' do
    sign_in users(:john_doe)

    group = groups(:group_one)

    group.create_logidze_snapshot!

    get group_history_path(group)

    assert_response :success

    w3c_validate 'Group History Page'
  end

  test 'view group history version' do
    sign_in users(:john_doe)

    group = groups(:group_one)

    group.create_logidze_snapshot!

    get group_history_path(group)

    get group_view_history_path(group, version: 1, format: :turbo_stream)

    assert_response :success
  end
end
