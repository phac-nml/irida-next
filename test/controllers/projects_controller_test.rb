# frozen_string_literal: true

require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should show the project' do
    sign_in users(:john_doe)

    get project_path(projects(:project1))
    assert_response :success
  end

  test 'should display create new project page' do
    sign_in users(:john_doe)

    get new_project_path
    assert_response :success
  end

  test 'should create a new group' do
    sign_in users(:john_doe)

    assert_difference('Project.count') do
      post projects_path,
           params: { project: { namespace_attributes: { name: 'My Personal Project', path: 'my-personal-project',
                                                        parent_id: namespaces_user_namespaces(:john_doe_namespace).id } } } # rubocop:disable Layout/LineLength
    end

    assert_redirected_to project_path(Project.last)
  end
end
