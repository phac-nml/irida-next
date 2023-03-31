# frozen_string_literal: true

require 'test_helper'

class ProjectsMembershipActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'project members index' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    get namespace_project_members_path(namespace, project)

    assert_response :success
    assert_equal 3, project.namespace.project_members.count
  end

  test 'project members index invalid route get' do
    sign_in users(:john_doe)

    assert_raises(ActionController::RoutingError) do
      get namespace_project_members_path(namespace_id: 'test-group-not-exists', project_id: 'test-proj-not-exists')
    end
  end

  test 'project members new' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)
    get new_namespace_project_member_path(namespace, project)

    assert_response :success
    assert_equal 3, project.namespace.project_members.count
  end

  test 'project members new invalid route get' do
    sign_in users(:john_doe)

    assert_raises(ActionController::RoutingError) do
      get new_namespace_project_member_path(namespace_id: 'test-group-not-exists', project_id: 'test-proj-not-exists')
    end
  end

  test 'project members create' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    proj_namespace = namespaces_project_namespaces(:john_doe_project2_namespace)
    project = projects(:john_doe_project2)

    user = users(:jane_doe)
    curr_user = users(:john_doe)

    post namespace_project_members_path(namespace, project),
         params: { member: { user_id: user.id,
                             namespace_id: proj_namespace,
                             created_by_id: curr_user.id,
                             type: 'GroupMember',
                             access_level: Member::AccessLevel::OWNER } }

    assert_redirected_to namespace_project_members_path(namespace, project)
    assert_equal 4, project.namespace.project_members.count
  end

  test 'project members create invalid route post' do
    sign_in users(:john_doe)
    user = users(:jane_doe)

    assert_raises(ActionController::RoutingError) do
      post namespace_project_members_path(namespace_id: 'does-not-exist', project_id: 'does-not-exist'),
           params: { member: { user_id: user.id,
                               namespace_id: 'does-not-exist',
                               created_by_id: users(:john_doe).id,
                               type: 'GroupMember',
                               access_level: Member::AccessLevel::OWNER } }
    end
  end

  test 'project members destroy' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    project_member = members_project_members(:project_two_member_james_doe)

    delete namespace_project_member_path(namespace, project, project_member)

    assert_redirected_to namespace_project_members_path(namespace, project)
    assert_equal 2, project.namespace.project_members.count
  end

  test 'project members destroy invalid route delete' do
    sign_in users(:john_doe)

    assert_raises(ActionController::RoutingError) do
      project_member = members_project_members(:project_two_member_james_doe)
      delete namespace_project_member_path('not-exists', 'not-exists', project_member)
    end
  end

  test 'project members create invalid' do
    sign_in users(:john_doe)
    user = users(:jane_doe)
    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    post namespace_project_members_path(namespace, project),
         params: { member: { user_id: user.id,
                             namespace_id: project.namespace.id,
                             created_by_id: users(:john_doe).id,
                             type: 'GroupMember',
                             access_level: Member::AccessLevel::OWNER + 100_000 } }

    assert_response 422 # unprocessable entity
  end

  test 'project members destroy invalid' do
    sign_in users(:joan_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)
    project_member = members_project_members(:project_two_member_james_doe)

    assert_no_changes -> { [project.namespace.project_members].count } do
      delete namespace_project_member_path(namespace, project, project_member)
    end

    # assert_response 422 # unprocessable entity
  end
end
