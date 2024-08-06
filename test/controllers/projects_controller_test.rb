# frozen_string_literal: true

require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should redirect to dashboard projects index when get index' do
    sign_in users(:john_doe)

    get projects_path
    assert_redirected_to dashboard_projects_path
  end

  test 'should show the project' do
    sign_in users(:john_doe)

    get project_path(projects(:project1))
    assert_response :success
  end

  test 'should not show the project if member is expired' do
    sign_in users(:john_doe)

    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save
    project_member = members(:project_one_member_john_doe)
    project_member.expires_at = 10.days.ago.to_date
    project_member.save
    get project_path(projects(:project1))
    assert_response :unauthorized
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

    assert_redirected_to project_samples_path(Project.last)
  end

  test 'should not create a new project under another user\'s namespace' do
    sign_in users(:david_doe)

    parent_namespace = namespaces_user_namespaces(:john_doe_namespace)

    assert_no_difference('Project.count') do
      post projects_path,
           params: { project: { namespace_attributes: { name: 'My Personal Project', path: 'my-personal-project',
                                                        parent_id: parent_namespace.id } } }
    end

    assert_response :unauthorized
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

  test 'should update a project which is a part of a parent group and of which the user is a member' do
    sign_in users(:john_doe)

    patch project_path(projects(:project2)),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } },
                    format: :turbo_stream }

    assert_redirected_to project_edit_path(projects(:project2).reload)
  end

  test 'should update a project which which is under the user\'s namespace' do
    sign_in users(:john_doe)

    project = projects(:john_doe_project2)

    patch project_path(project),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } },
                    format: :turbo_stream }

    assert_redirected_to project_edit_path(project.reload)
  end

  test 'should not update a project which which is under another user\'s namespace' do
    sign_in users(:david_doe)

    project = projects(:john_doe_project2)

    patch project_path(project),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } } }

    assert_response :unauthorized
  end

  test 'should fail to update a project with wrong params' do
    sign_in users(:david_doe)

    project = projects(:john_doe_project2)

    patch project_path(project),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'VERY BAD PATH' } } }

    assert_response :unauthorized
  end

  test 'should delete a project' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    assert_difference('Project.count', -1) do
      delete namespace_project_path(namespace_id: namespace.path, project_id: project.namespace.path)
    end

    assert_redirected_to dashboard_projects_path(format: :html)
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

  test 'should not show the project edit page' do
    sign_in users(:david_doe)
    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    get namespace_project_edit_path(namespace, project)

    assert_response :unauthorized
  end

  test 'should show the group edit page' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    get namespace_project_edit_path(namespace, project)

    assert_response :success
  end

  test 'should show the new project page' do
    sign_in users(:john_doe)
    namespace = namespaces_user_namespaces(:john_doe_namespace)

    get new_project_path(namespace:)

    assert_response :success
  end

  test 'should show the project activity page' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    get namespace_project_activity_path(namespace, project)

    assert_response :success
  end

  test 'should not show the project activity page' do
    sign_in users(:david_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    get namespace_project_activity_path(namespace, project)

    assert_response :unauthorized
  end

  test 'should not create a project under another user\'s namespace' do
    sign_in users(:david_doe)

    parent_namespace = namespaces_user_namespaces(:john_doe_namespace)

    post projects_path,
         params: {
           project: {
             namespace_attributes: {
               name: 'My Personal Project',
               path: 'my-personal-project',
               parent_id: parent_namespace.id
             }
           }
         }

    assert_response :unauthorized
  end

  test 'should transfer project' do
    project = projects(:project1)
    namespace = namespaces_user_namespaces(:john_doe_namespace)
    old_namespace = groups(:group_one)

    post namespace_project_samples_transfer_path(old_namespace, project),
         params: { new_namespace_id: namespace.id }, as: :turbo_stream

    assert_response :redirect
  end

  test 'should not transfer a project to unowned namespace' do
    sign_in users(:david_doe)
    project = projects(:project1)
    old_namespace = groups(:group_one)
    post namespace_project_transfer_path(old_namespace, project),
         params: { new_namespace_id: groups(:david_doe_group_four).id },
         as: :turbo_stream

    assert_response :unauthorized
  end
end
