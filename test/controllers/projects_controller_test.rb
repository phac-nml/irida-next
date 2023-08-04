# frozen_string_literal: true

require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
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
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } } }

    assert_redirected_to project_path(projects(:project2).reload)
  end

  test 'should update a project which which is under the user\'s namespace' do
    sign_in users(:john_doe)

    project = projects(:john_doe_project2)

    patch project_path(project),
          params: { project: { namespace_attributes: { name: 'Awesome Project 2', path: 'awesome-project-2' } } }

    assert_redirected_to project_path(project.reload)
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

  test 'should not create a new transfer with wrong parameters' do
    sign_in users(:david_doe)
    project = projects(:project1)
    old_namespace = groups(:group_one)
    post namespace_project_samples_transfer_path(old_namespace, project),
         params: { new_namespace_id: 'asdfasd' }, as: :turbo_stream

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

  test 'should share project namespace with group' do
    sign_in users(:john_doe)
    namespace = groups(:group_one)
    project = projects(:project22)
    project_namespace = project.namespace

    post namespace_project_share_path(project_namespace.parent, project,
                                      params: { shared_group_id: namespace.id,
                                                group_access_level: Member::AccessLevel::ANALYST })

    assert_redirected_to namespace_project_path(project_namespace.parent, project_namespace.project)
  end

  test 'should not share project with group as group doesn\'t exist' do
    sign_in users(:john_doe)
    group_id = 1
    project_namespace = namespaces_project_namespaces(:project1_namespace)

    post namespace_project_share_path(project_namespace.parent, project_namespace.project,
                                      params: { shared_group_id: group_id,
                                                group_access_level: Member::AccessLevel::ANALYST })

    assert_response :unprocessable_entity
  end

  test 'shouldn\'t share project namespace with group as user doesn\'t have correct permissions' do
    sign_in users(:micha_doe)
    group = groups(:group_one)
    project_namespace = namespaces_project_namespaces(:project23_namespace)

    post namespace_project_share_path(project_namespace.parent, project_namespace.project,
                                      params: { shared_group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST })

    assert_response :unauthorized
  end

  test 'project namespace already shared with group' do
    sign_in users(:john_doe)
    group = groups(:group_one)
    project_namespace = namespaces_project_namespaces(:project1_namespace)

    post namespace_project_share_path(project_namespace.parent, project_namespace.project,
                                      params: { shared_group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST })

    namespace_project_path(project_namespace.parent,
                           project_namespace.project)

    post namespace_project_share_path(project_namespace.parent, project_namespace.project,
                                      params: { shared_group_id: group.id,
                                                group_access_level: Member::AccessLevel::ANALYST })

    assert_response :conflict
  end

  test 'unshare project' do
    sign_in users(:john_doe)
    namespace_group_link = namespace_group_links(:namespace_group_link1)
    group = namespace_group_link.group
    project_namespace = namespace_group_link.namespace

    post namespace_project_unshare_path(project_namespace.parent, project_namespace.project,
                                        params: { shared_group_id: group.id })

    assert_redirected_to namespace_project_path(project_namespace.parent, project_namespace.project)
  end

  test 'unshare project when link doesn\'t exist' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    project_namespace = namespaces_project_namespaces(:project23_namespace)

    post namespace_project_unshare_path(project_namespace.parent, project_namespace.project,
                                        params: { shared_group_id: group.id })

    assert_response :unprocessable_entity
  end
end
