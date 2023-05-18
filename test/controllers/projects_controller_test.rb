# frozen_string_literal: true

require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in users(:john_doe)

    get projects_path
    assert_response :success
  end

  test 'should show the project' do
    sign_in users(:john_doe)

    get project_path(projects(:project1))
    assert_response :success
  end

  test 'should not show the project' do
    sign_in users(:micha_doe)

    get project_path(projects(:project1))
    assert_response :unauthorized
  end

  test 'should show 404 if project does not exist' do
    sign_in users(:john_doe)

    get namespace_project_path(project_id: 'does-not-exist', namespace_id: 'does-not-exist')
    assert_response :not_found
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

  test 'should fail to create a new project with wrong params' do
    sign_in users(:john_doe)

    parent_namespace = namespaces_user_namespaces(:john_doe_namespace)

    post projects_path,
         params: {
           project: {
             namespace_attributes: {
               name: 'My Personal Project',
               path: 'a VERY wrong path',
               parent_id: parent_namespace.id
             }
           }
         }

    assert_response :unprocessable_entity
  end

  test 'should update a project' do
    sign_in users(:john_doe)

    patch project_path(projects(:project2)),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } } }

    assert_redirected_to project_path(projects(:project2).reload)
  end

  test 'should fail to update a project with wrong params' do
    sign_in users(:john_doe)

    patch project_path(projects(:project2)),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'a VERY wrong path' } } }

    assert_response :unprocessable_entity
  end

  test 'should transfer a project' do
    sign_in users(:john_doe)

    post project_transfer_path(projects(:project2)),
         params: { new_namespace_id: groups(:subgroup1).id }

    assert_redirected_to project_path(projects(:project2).reload)
  end

  test 'should not transfer a project' do
    sign_in users(:john_doe)

    post project_transfer_path(projects(:project2)),
         params: { new_namespace_id: groups(:david_doe_group_four).id }

    assert_response :unauthorized
  end

  test 'should fail to transfer a project with wrong params' do
    sign_in users(:john_doe)

    post project_transfer_path(projects(:project2)),
         params: {
           new_namespace_id: 'does-not-exist'
         }

    assert_response :unprocessable_entity
  end

  test 'should delete a project' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    assert_difference('Project.count', -1) do
      delete namespace_project_path(namespace_id: namespace.path, project_id: project.namespace.path)
    end

    assert_redirected_to projects_path
  end

  test 'should not delete a project' do
    sign_in users(:joan_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    assert_no_difference('Project.count') do
      delete namespace_project_path(namespace_id: namespace.path, project_id: project.namespace.path)
    end

    assert_response :unauthorized
  end
end
