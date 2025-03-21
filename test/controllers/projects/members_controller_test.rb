# frozen_string_literal: true

require 'test_helper'

module Projects
  class MembersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get project members listing => projects/members#index' do
      sign_in users(:john_doe)
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      get namespace_project_members_path(namespace, project)
      assert_response :success

      w3c_validate 'Project Members Page'
    end

    test 'should display add new member to project page' do
      sign_in users(:john_doe)
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      get new_namespace_project_member_path(namespace, project, format: :turbo_stream)
      assert_response :success
    end

    test 'should add new member to project' do
      sign_in users(:john_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      get new_namespace_project_member_path(namespace, project, format: :turbo_stream)
      created_by_user = users(:john_doe)
      user = users(:jane_doe)

      assert_difference('Member.count') do
        post namespace_project_members_path, params: { member: { user_id: user.id,
                                                                 namespace_id: namespace.id,
                                                                 created_by_id: created_by_user.id,
                                                                 access_level: Member::AccessLevel::OWNER },
                                                       format: :turbo_stream }
      end

      assert_response :success
    end

    test 'should delete a member from the project' do
      sign_in users(:john_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      get new_namespace_project_member_path(namespace, project, format: :turbo_stream)
      project_member = members(:project_two_member_james_doe)

      assert_difference('Member.count', -1) do
        delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
      end

      assert_response :ok
    end

    test 'shouldn\'t delete a member from the project' do
      sign_in users(:joan_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      project_member = members(:project_two_member_james_doe)

      assert_no_difference('Member.count') do
        delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
      end

      assert_response :unprocessable_entity
    end
  end
end
