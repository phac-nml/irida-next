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

  test 'should create a new project' do
    sign_in users(:john_doe)

    parent_namespace = namespaces_user_namespaces(:john_doe_namespace)

    assert_difference('Project.count') do
      post projects_path,
           params: { project: { namespace_attributes: { name: 'My Personal Project', path: 'my-personal-project',
                                                        parent_id: parent_namespace.id } } }
    end

    assert_redirected_to project_path(Project.last)
  end

  test 'should update a project' do
    sign_in users(:john_doe)

    patch project_path(projects(:project2)),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } } }

    assert_redirected_to project_path(projects(:project2).reload)
  end

  test 'should transfer a project' do
    sign_in users(:john_doe)

    post project_transfer_path(projects(:project2)),
         params: { new_namespace_id: groups(:subgroup1).id }

    assert_redirected_to project_path(projects(:project2).reload)
  end
end
