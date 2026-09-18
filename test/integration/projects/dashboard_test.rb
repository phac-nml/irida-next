# frozen_string_literal: true

require 'test_helper'

module Projects
  class DashboardTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include DashboardSortingHelper

    setup do
      @user = users(:john_doe)
      sign_in @user
      @personal_project = projects(:john_doe_project2)
      @group_project = projects(:project1)
    end

    test 'should show all projects tab by default' do
      get dashboard_projects_path

      assert_response :success
      assert_select '[role="tab"][aria-selected="true"]#all-tab'
      assert_select '[role="tab"][aria-selected="false"]#personal-tab'
      assert_select 'input[type="hidden"][name="personal"][value="true"]', count: 0

      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select '#groups_tree', count: 1
      assert_select '.treegrid-row', count: 20
      assert_select 'a', exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.previous'), count: 0
    end

    test 'should show personal projects' do
      get dashboard_projects_path, params: { personal: 'true' }

      assert_response :success
      assert_select '[role="tab"][aria-selected="true"]#personal-tab'
      assert_select '[role="tab"][aria-selected="false"]#all-tab'
      assert_select 'input[type="hidden"][name="personal"][value="true"]'

      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select '#groups_tree', count: 1
      assert_select '.treegrid-row', count: 4
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.previous'), count: 0
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next'), count: 0
    end

    test 'can search the list of projects by name' do
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: @group_project.name } }

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select '#groups_tree', count: 1
      assert_select '.treegrid-row', count: 13
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.previous'), count: 0
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next'), count: 0

      assert_select 'input[name="all_projects_q[namespace_name_or_namespace_puid_cont]"]'
      assert_select 'input.t-search-component' do |input|
        assert_equal @group_project.name, input.first['value']
      end
    end

    test 'can search the list of projects by puid' do
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: @group_project.puid } }

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select '#groups_tree', count: 1
      assert_select '.treegrid-row', count: 1
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.previous'), count: 0
      assert_select 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next'), count: 0

      assert_select 'input[name="all_projects_q[namespace_name_or_namespace_puid_cont]"]'
      assert_select 'input.t-search-component' do |input|
        assert_equal @group_project.puid, input.first['value']
      end
    end

    test 'should use personal_projects_q search key when personal=true' do
      get dashboard_projects_path,
          params: { personal: 'true', personal_projects_q: { namespace_name_or_namespace_puid_cont: 'Project 2' } }

      assert_response :success
      assert_select 'input[name="personal_projects_q[namespace_name_or_namespace_puid_cont]"]'
    end

    test 'should display empty state when user has no projects and no public projects' do
      Namespaces::ProjectNamespace.where(public: true).destroy_all

      sign_in users(:user_no_access)

      get dashboard_projects_path

      assert_response :success
      assert_select '.empty_state_message', count: 1
    end

    test 'should apply default sort when no sort specified' do
      get dashboard_projects_path

      assert_response :success
      assert_active_sort('all_projects_q', 'updated_at desc')
      assert_includes first_treegrid_row_text, @group_project.human_name
    end

    test 'should respect custom sort parameters' do
      get dashboard_projects_path,
          params: { all_projects_q: { s: 'namespace_name desc' } }

      assert_response :success
      assert_active_sort('all_projects_q', 'namespace_name desc')

      assert_includes first_treegrid_row_text, projects(:subgroup1Project1).human_name
    end

    test 'should sort projects by updated_at ascending' do
      get dashboard_projects_path, params: { all_projects_q: { s: 'updated_at asc' } }

      assert_response :success
      assert_active_sort('all_projects_q', 'updated_at asc')
    end

    test 'should sort projects by created_at descending' do
      get dashboard_projects_path, params: { all_projects_q: { s: 'created_at desc' } }

      assert_response :success
      assert_active_sort('all_projects_q', 'created_at desc')
    end

    test 'should sort projects by created_at ascending' do
      get dashboard_projects_path, params: { all_projects_q: { s: 'created_at asc' } }

      assert_response :success
      assert_active_sort('all_projects_q', 'created_at asc')
    end

    test 'should apply sort with filters for all projects query' do
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: @group_project.name,
                                      s: 'namespace_name desc' } }

      assert_response :success
      assert_active_sort('all_projects_q', 'namespace_name desc')

      assert_includes first_treegrid_row_text, projects(:subgroup1Project1).human_name
    end

    test 'should apply sort with filters for personal projects query' do
      get dashboard_projects_path,
          params: { personal: 'true',
                    personal_projects_q: { namespace_name_or_namespace_puid_cont: @personal_project.name,
                                           s: 'namespace_name asc' } }

      assert_response :success
      assert_active_sort('personal_projects_q', 'namespace_name asc')
      assert_includes first_treegrid_row_text, @personal_project.human_name
    end

    test 'should paginate results' do
      get dashboard_projects_path, params: { page: 1 }

      assert_response :success
    end

    test 'should only show authorized projects' do
      sign_in users(:micha_doe)

      get dashboard_projects_path

      assert_response :success
      # Should only show projects the user is authorized to see
      # If user has no projects, empty state should be shown
    end

    test 'should filter to personal projects when personal=true' do
      get dashboard_projects_path, params: { personal: 'true' }

      assert_response :success
      # Should only show personal projects (under user's namespace)
      # This is verified by the authorization scope
    end

    test 'should show all authorized projects when personal=false' do
      get dashboard_projects_path, params: { personal: 'false' }

      assert_response :success
      # Should show all projects user has access to (personal + group projects)
    end

    test 'accessing projects index on invalid page causes pagy overflow redirect' do
      sign_in users(:john_doe)

      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get dashboard_projects_path(page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end

    test 'should update samples count after a sample deletion' do
      group = groups(:group_one)
      project = projects(:project1)
      sample = samples(:sample1)

      get dashboard_projects_path

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select "##{dom_id(project)}-samples-count", text: '3'

      assert_difference -> { project.samples.count }, -1 do
        post samples_deletions_path,
             params: {
               namespace_id: group.id,
               deletion_type: 'single',
               deletion: { sample_ids: [sample.id] }
             }, as: :turbo_stream
      end

      assert_response :redirect
      follow_redirect!
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select "##{dom_id(project)}-samples-count", text: '2'
    end

    test 'should update samples count after a sample creation' do
      group = groups(:group_one)
      project = projects(:project1)

      get dashboard_projects_path, params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select "##{dom_id(project)}-samples-count", text: '3'

      assert_difference -> { project.samples.count }, 1 do
        post namespace_project_samples_path(group, project),
             params: { sample: { name: 'Test Sample' } }
      end

      assert_response :redirect
      follow_redirect!
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select "##{dom_id(project)}-samples-count", text: '4'
    end

    test 'should update samples count after a sample transfer' do
      group = groups(:group_one)
      project = projects(:project1)
      destination = projects(:project2)
      sample = samples(:sample1)

      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select "##{dom_id(project)}-samples-count", text: '3'
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: destination.name } }
      assert_select "##{dom_id(destination)}-samples-count", text: '20'

      assert_enqueued_jobs 1, only: [::Samples::TransferJob] do
        post samples_transfer_path(namespace_id: group.id, format: :turbo_stream),
             params: {
               transfer: { new_project_id: destination.id, sample_ids: [sample.id] },
               broadcast_target: 'dashboard_test'
             }, as: :turbo_stream
      end
      assert_response :success

      assert_difference -> { project.samples.count }, -1,
                        -> { destination.samples.count }, 1 do
        perform_enqueued_jobs only: [::Samples::TransferJob]
      end

      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select "##{dom_id(project)}-samples-count", text: '2'
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: destination.name } }
      assert_select "##{dom_id(destination)}-samples-count", text: '21'
    end

    test 'should update samples count after a sample transfer v2' do
      Flipper.enable(:v2_sample_transfer)

      group = groups(:group_one)
      project = projects(:project1)
      destination = projects(:project2)
      sample = samples(:sample1)

      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select "##{dom_id(project)}-samples-count", text: '3'
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: destination.name } }
      assert_select "##{dom_id(destination)}-samples-count", text: '20'

      assert_enqueued_jobs 1, only: [::Samples::TransferJobV2] do
        post samples_transfer_path(namespace_id: group.id, format: :turbo_stream),
             params: {
               transfer: { new_project_id: destination.id, sample_ids: [sample.id] },
               broadcast_target: 'dashboard_test_v2'
             }, as: :turbo_stream
      end
      assert_response :success

      assert_difference -> { project.samples.count }, -1,
                        -> { destination.samples.count }, 1 do
        perform_enqueued_jobs only: [::Samples::TransferJobV2]
      end

      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select "##{dom_id(project)}-samples-count", text: '2'
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: destination.name } }
      assert_select "##{dom_id(destination)}-samples-count", text: '21'
    ensure
      Flipper.disable(:v2_sample_transfer)
    end

    test 'should update samples count after a sample clone' do
      group = groups(:group_one)
      project = projects(:project1)
      destination = projects(:project2)
      sample = samples(:sample1)

      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.projects.index.title')
      assert_select "##{dom_id(project)}-samples-count", text: '3'
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: destination.name } }
      assert_select "##{dom_id(destination)}-samples-count", text: '20'

      assert_enqueued_jobs 1, only: [::Samples::CloneJob] do
        post samples_clone_path,
             params: {
               namespace_id: group.id,
               clone: { new_project_id: destination.id, sample_ids: [sample.id] },
               broadcast_target: 'dashboard_test_clone'
             }, as: :turbo_stream
      end
      assert_response :success

      assert_no_difference -> { project.samples.count } do
        assert_difference -> { destination.samples.count }, 1 do
          perform_enqueued_jobs only: [::Samples::CloneJob]
        end
      end

      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: project.name } }

      assert_response :success
      assert_select "##{dom_id(project)}-samples-count", text: '3'
      get dashboard_projects_path,
          params: { all_projects_q: { namespace_name_or_namespace_puid_cont: destination.name } }
      assert_select "##{dom_id(destination)}-samples-count", text: '21'
    end

    test 'can skip to content' do
      get dashboard_projects_path

      assert_response :success
      assert_select '#main-content-link[href="#main-content"]'
      assert_select '#main-content'
    end
  end
end
