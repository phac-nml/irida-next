# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesTest < ActionDispatch::IntegrationTest
    include ActionView::RecordIdentifier

    setup do
      @user = users(:john_doe)
      sign_in @user
      @sample1 = samples(:sample1)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'index renders the samples table with headers and rows' do
      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_select 'h1', text: I18n.t('projects.samples.index.title')
      assert_samples_table_headers
      assert_select 'table tbody tr', count: 3
      assert_select "table tbody tr##{dom_id(@sample1)} th:first-child", text: /#{Regexp.escape(@sample1.puid)}/
      assert_select "table tbody tr##{dom_id(@sample1)} td:nth-child(2)", text: /#{Regexp.escape(@sample1.name)}/
    end

    test 'index renders the data grid when the flag is enabled' do
      Flipper.enable(:data_grid_samples_table)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :success
      assert_samples_data_grid
    ensure
      Flipper.disable(:data_grid_samples_table)
    end

    test 'selection controls visibility by role' do
      [[@user, true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_selection_controls(@sample1, present:)
      end
    end

    test 'workflow execution link visibility by role' do
      [[users(:james_doe), true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_workflow_execution_link(present:, locale: user.locale)
      end
    end

    test 'sample actions dropdown visibility by role' do
      [[@user, true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_dropdown(present:, locale: user.locale)
      end
    end

    test 'export actions visibility by role' do
      [[users(:james_doe), true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get namespace_project_samples_url(@namespace, @project)

        assert_response :success
        assert_actions_menu_item('linelist_export', present:, locale: user.locale)
        assert_actions_menu_item('sample_export', present:, locale: user.locale)
      end
    end

    test 'import metadata action visibility by role' do
      project24 = projects(:project24)

      [[@user, @namespace, @project, true],
       [users(:michelle_doe), project24.parent, project24, false]].each do |user, namespace, project, present|
        sign_in user

        get namespace_project_samples_url(namespace, project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('import_metadata', present:, locale: user.locale)
      end
    end

    test 'new sample action visibility by role' do
      project24 = projects(:project24)

      [[@user, @namespace, @project, true],
       [users(:michelle_doe), project24.parent, project24, false]].each do |user, namespace, project, present|
        sign_in user

        get namespace_project_samples_url(namespace, project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('new_sample', present:, locale: user.locale)
      end
    end

    test 'delete samples action visibility by role' do
      project24 = projects(:project24)

      [[@user, @namespace, @project, true],
       [users(:michelle_doe), project24.parent, project24, false]].each do |user, namespace, project, present|
        sign_in user

        get namespace_project_samples_url(namespace, project)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('delete_samples', present:, locale: user.locale)
      end
    end

    test 'cannot access project samples without authorization' do
      sign_in users(:user_no_access)

      get namespace_project_samples_url(@namespace, @project)

      assert_response :unauthorized
    end

    test 'quick search highlights matching sample names' do
      get namespace_project_samples_url(@namespace, @project, q: { name_or_puid_cont: 'sample' })

      assert_response :success
      assert_select 'table tbody tr', count: 3
      assert_select 'mark', text: /sample/i, minimum: 3
    end

    test 'quick search highlights matching sample puid' do
      get namespace_project_samples_url(@namespace, @project, q: { name_or_puid_cont: @sample1.puid })

      assert_response :success
      assert_select 'table tbody tr', count: 1
      assert_select 'mark', text: /#{Regexp.escape(@sample1.puid)}/
    end

    test 'renders the empty state when a project has no samples' do
      sign_in users(:empty_doe)

      get namespace_project_samples_url(groups(:empty_group), projects(:empty_project))

      assert_response :success
      assert_match I18n.t('projects.samples.index.no_samples'), response.body
      assert_match I18n.t('projects.samples.index.no_associated_samples'), response.body
    end
  end
end
