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

    w3c_validate 'Project Members Page'
  end

  test 'project members index invalid route get' do
    sign_in users(:john_doe)

    get namespace_project_members_path(namespace_id: 'test-group-not-exists', project_id: 'test-proj-not-exists')
    assert_response :not_found
  end

  test 'project members new' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)
    get new_namespace_project_member_path(namespace, project, format: :turbo_stream)

    assert_response :success
  end

  test 'project members new invalid route get' do
    sign_in users(:john_doe)

    get new_namespace_project_member_path(namespace_id: 'test-group-not-exists', project_id: 'test-proj-not-exists')
    assert_response :not_found
  end

  test 'project members create' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    proj_namespace = namespaces_project_namespaces(:john_doe_project2_namespace)
    project = projects(:john_doe_project2)

    user = users(:jane_doe)
    curr_user = users(:john_doe)

    assert_difference -> { project.namespace.project_members.count } => 1 do
      post namespace_project_members_path(namespace, project),
           params: { member: { user_id: user.id,
                               namespace_id: proj_namespace,
                               created_by_id: curr_user.id,
                               access_level: Member::AccessLevel::OWNER }, format: :turbo_stream }
    end

    assert_response :success
  end

  test 'project members create invalid route post' do
    sign_in users(:john_doe)
    user = users(:jane_doe)

    post namespace_project_members_path(namespace_id: 'does-not-exist', project_id: 'does-not-exist'),
         params: { member: { user_id: user.id,
                             namespace_id: 'does-not-exist',
                             created_by_id: users(:john_doe).id,
                             access_level: Member::AccessLevel::OWNER } }
    assert_response :not_found
  end

  test 'project members destroy' do
    sign_in users(:john_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)

    project_member = members(:project_two_member_james_doe)

    assert_difference -> { project.namespace.project_members.count } => -1 do
      delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
    end

    assert_response :ok
  end

  test 'project members destroy invalid route delete' do
    sign_in users(:john_doe)

    project_member = members(:project_two_member_james_doe)
    delete namespace_project_member_path('not-exists', 'not-exists', project_member)
    assert_response :not_found
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
                             access_level: Member::AccessLevel::OWNER + 100_000 }, format: :turbo_stream }

    assert_response :unprocessable_entity
  end

  test 'project members destroy member with owner role when current user has a maintainer role for project' do
    # Joan Doe has a maintainer role for john_doe_project2
    sign_in users(:joan_doe)

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    project = projects(:john_doe_project2)
    # James Doe has an owner role for john_doe_project2
    project_member = members(:project_two_member_james_doe)

    assert_no_changes -> { [project.namespace.project_members].count } do
      delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
    end

    assert_response :unprocessable_entity
  end

  test 'project members create with maintainer role' do
    user = users(:joan_doe)
    sign_in user

    namespace = namespaces_user_namespaces(:john_doe_namespace)
    proj_namespace = namespaces_project_namespaces(:john_doe_project4_namespace)
    project = projects(:john_doe_project4)

    user_new = users(:jane_doe)

    assert_difference -> { project.namespace.project_members.count } => 1 do
      post namespace_project_members_path(namespace, project),
           params: { member: { user_id: user_new.id,
                               namespace_id: proj_namespace,
                               created_by_id: user.id,
                               access_level: Member::AccessLevel::ANALYST }, format: :turbo_stream }
    end

    assert_response :success
  end

  test 'update project member access role with current user as owner' do
    sign_in users(:john_doe)

    project = projects(:project22)
    namespace = groups(:group_five)
    project_member = members(:project_twenty_two_member_michelle_doe)

    patch namespace_project_member_path(namespace, project, project_member),
          params: { member: {
            access_level: Member::AccessLevel::ANALYST
          }, format: :turbo_stream }

    assert_equal Member.find_by(user_id: project_member.user.id,
                                namespace_id: project_member.namespace.id).access_level,
                 Member::AccessLevel::ANALYST

    assert_response :success
  end

  test 'update project member access role with current user as maintainer' do
    sign_in users(:micha_doe)

    project = projects(:project22)
    namespace = groups(:group_five)
    project_member = members(:project_twenty_two_member_michelle_doe)

    patch namespace_project_member_path(namespace, project, project_member),
          params: { member: {
            access_level: Member::AccessLevel::ANALYST
          }, format: :turbo_stream }

    assert_equal Member.find_by(user_id: project_member.user.id,
                                namespace_id: project_member.namespace.id).access_level,
                 Member::AccessLevel::ANALYST

    assert_response :success
  end

  test 'update project member access role to lower level than group' do
    sign_in users(:john_doe)

    project = projects(:project22)
    namespace = groups(:group_five)
    project_member = members(:project_twenty_two_member_james_doe)

    assert_no_changes -> { project_member.access_level } do
      patch namespace_project_member_path(namespace, project, project_member),
            params: { member: {
              access_level: Member::AccessLevel::ANALYST
            }, format: :turbo_stream }
    end

    assert_not_equal Member.find_by(user_id: project_member.user.id,
                                    namespace_id: project_member.namespace.id).access_level,
                     Member::AccessLevel::ANALYST

    assert_response :bad_request
  end

  test 'update project member access role to non existent access level' do
    sign_in users(:john_doe)

    project = projects(:project22)
    namespace = groups(:group_five)
    project_member = members(:project_twenty_two_member_james_doe)

    assert_no_changes -> { project_member.access_level } do
      patch namespace_project_member_path(namespace, project, project_member),
            params: { member: {
              access_level: 100_000
            }, format: :turbo_stream }
    end

    assert_not_equal Member.find_by(user_id: project_member.user.id,
                                    namespace_id: project_member.namespace.id).access_level,
                     100_000

    assert_response :bad_request
  end
end
