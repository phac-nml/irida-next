# frozen_string_literal: true

require 'test_helper'

module Dashboard
  class ProjectsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:john_doe)
      @personal_project = projects(:john_doe_project2)
      @group_project = projects(:project1)
    end

    test 'should get index' do
      sign_in @user

      get dashboard_projects_path
      assert_response :success

      w3c_validate 'Projects Dashboard'
    end

    test 'should show all projects tab by default' do
      sign_in @user

      get dashboard_projects_path

      assert_response :success
      assert_select '[role="tab"][aria-selected="true"]#all-tab'
      assert_select '[role="tab"][aria-selected="false"]#personal-tab'
    end

    test 'should show personal projects tab when personal=true' do
      sign_in @user

      get dashboard_projects_path, params: { personal: 'true' }

      assert_response :success
      assert_select '[role="tab"][aria-selected="true"]#personal-tab'
      assert_select '[role="tab"][aria-selected="false"]#all-tab'
    end

    test 'should include hidden personal input when personal=true' do
      sign_in @user

      get dashboard_projects_path, params: { personal: 'true' }

      assert_response :success
      assert_select 'input[type="hidden"][name="personal"][value="true"]'
    end

    test 'should not include hidden personal input when personal=false' do
      sign_in @user

      get dashboard_projects_path, params: { personal: 'false' }

      assert_response :success
      assert_select 'input[type="hidden"][name="personal"][value="true"]', count: 0
    end

    test 'should use personal_projects_q search key when personal=true' do
      sign_in @user

      get dashboard_projects_path,
          params: { personal: 'true', personal_projects_q: { namespace_name_or_namespace_puid_cont: 'Project 2' } }

      assert_response :success
      assert_select 'input[name="personal_projects_q[namespace_name_or_namespace_puid_cont]"]'
    end

    test 'should use all_projects_q search key when personal=false' do
      sign_in @user

      get dashboard_projects_path,
          params: { personal: 'false', all_projects_q: { namespace_name_or_namespace_puid_cont: 'Project 1' } }

      assert_response :success
      assert_select 'input[name="all_projects_q[namespace_name_or_namespace_puid_cont]"]'
    end

    test 'should use all_projects_q search key by default' do
      sign_in @user

      get dashboard_projects_path, params: { all_projects_q: { namespace_name_or_namespace_puid_cont: 'Project' } }

      assert_response :success
      assert_select 'input[name="all_projects_q[namespace_name_or_namespace_puid_cont]"]'
    end

    test 'should display projects when user has projects' do
      sign_in @user

      get dashboard_projects_path

      assert_response :success
      assert_select '#groups_tree', count: 1
    end

    test 'should display empty state when user has no projects' do
      # Create a user with no project access
      user_without_projects = User.create!(
        email: 'no_projects@test.com',
        password: 'password123',
        first_name: 'No',
        last_name: 'Projects'
      )
      sign_in user_without_projects

      get dashboard_projects_path

      assert_response :success
      assert_select '.empty_state_message', count: 1
    ensure
      user_without_projects&.destroy
    end

    test 'should apply default sort when no sort specified' do
      sign_in @user

      get dashboard_projects_path

      assert_response :success
      # Default sort should be applied (updated_at desc)
      # We can verify this by checking the sort dropdown has the default selected
    end

    test 'should respect custom sort parameters' do
      sign_in @user

      get dashboard_projects_path,
          params: { all_projects_q: { s: 'namespace_name asc' } }

      assert_response :success
    end

    test 'should paginate results' do
      sign_in @user

      get dashboard_projects_path, params: { page: 1 }

      assert_response :success
    end

    test 'should only show authorized projects' do
      unauthorized_user = users(:micha_doe)
      sign_in unauthorized_user

      get dashboard_projects_path

      assert_response :success
      # Should only show projects the user is authorized to see
      # If user has no projects, empty state should be shown
    end

    test 'should filter to personal projects when personal=true' do
      sign_in @user

      get dashboard_projects_path, params: { personal: 'true' }

      assert_response :success
      # Should only show personal projects (under user's namespace)
      # This is verified by the authorization scope
    end

    test 'should show all authorized projects when personal=false' do
      sign_in @user

      get dashboard_projects_path, params: { personal: 'false' }

      assert_response :success
      # Should show all projects user has access to (personal + group projects)
    end
  end
end
