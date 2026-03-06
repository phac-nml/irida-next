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
      get new_namespace_project_member_path(namespace, project)
      assert_response :success
    end

    test 'should apply default sort and support sorting project members' do
      sign_in users(:john_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      project_member_james = members(:project_two_member_james_doe)
      project_member_jean = members(:project_two_member_jean_doe)
      project_member_joan = members(:project_two_member_joan_doe)
      project_member_ryan = members(:project_two_member_ryan_doe)
      owner_emails = [members(:project_two_member_james_doe).user.email, members(:project_two_member_john_doe).user.email]

      get namespace_project_members_path(namespace, project, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(project_member_james.user.email, project_member_jean.user.email,
                                row_scope: '#members-table-body')

      get namespace_project_members_path(namespace, project, format: :turbo_stream, members_q: { s: 'user_email desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(project_member_ryan.user.email, members(:project_two_member_john_doe).user.email,
                                row_scope: '#members-table-body')

      get namespace_project_members_path(namespace, project, format: :turbo_stream, members_q: { s: 'access_level asc' })
      assert_response :success
      assert_sort_state(2, 'ascending')
      member_emails = Nokogiri::HTML(response.body).css('#members-table-body tr td:first-child').filter_map do |node|
        node.text[/[A-Za-z0-9_.+\-]+@[A-Za-z0-9\-.]+/]
      end
      assert_equal project_member_ryan.user.email, member_emails.first
      assert_includes owner_emails, member_emails.last

      get namespace_project_members_path(namespace, project, format: :turbo_stream, members_q: { s: 'access_level desc' })
      assert_response :success
      assert_sort_state(2, 'descending')
      member_emails = Nokogiri::HTML(response.body).css('#members-table-body tr td:first-child').filter_map do |node|
        node.text[/[A-Za-z0-9_.+\-]+@[A-Za-z0-9\-.]+/]
      end
      assert_includes owner_emails, member_emails.first
      assert_equal project_member_ryan.user.email, member_emails.last

      get namespace_project_members_path(namespace, project, format: :turbo_stream, members_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(project_member_joan.user.email, project_member_ryan.user.email,
                                row_scope: '#members-table-body')
    end

    test 'should add new member to project' do
      sign_in users(:john_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      get new_namespace_project_member_path(namespace, project)
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

      get new_namespace_project_member_path(namespace, project)
      project_member = members(:project_two_member_james_doe)

      assert_difference('Member.count', -1) do
        delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
      end

      assert_response :ok
    end

    test 'should redirect user to projects dashboard when they leave the project' do
      sign_in users(:james_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      get new_namespace_project_member_path(namespace, project)
      project_member = members(:project_two_member_james_doe)

      assert_difference('Member.count', -1) do
        delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
      end

      assert_redirected_to dashboard_projects_url
    end

    test 'shouldn\'t delete a member from the project' do
      sign_in users(:joan_doe)

      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      project_member = members(:project_two_member_james_doe)

      assert_no_difference('Member.count') do
        delete namespace_project_member_path(namespace, project, project_member, format: :turbo_stream)
      end

      assert_response :unprocessable_content
    end
  end
end
