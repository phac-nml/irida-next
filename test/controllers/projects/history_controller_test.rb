# frozen_string_literal: true

require 'test_helper'

module Projects
  class HistoryControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get project history listing => projects/history#index' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)
      project.namespace.create_logidze_snapshot!

      get namespace_project_history_path(namespace, project)
      assert_response :success

      w3c_validate 'Project History Page'
    end

    test 'should display project history version' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)
      project.namespace.create_logidze_snapshot!

      get namespace_project_view_history_path(namespace, project, version: 1, format: :turbo_stream)
      assert_response :success
    end
  end
end
