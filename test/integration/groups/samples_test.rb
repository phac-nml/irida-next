# frozen_string_literal: true

require 'test_helper'

module Groups
  class SamplesTest < ActionDispatch::IntegrationTest
    include ActionView::RecordIdentifier

    setup do
      @user = users(:john_doe)
      sign_in @user
      @group = groups(:group_one)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample3 = samples(:sample3)
    end

    test 'index renders the samples table with headers and rows' do
      get group_samples_url(@group)

      assert_response :success
      assert_select 'h1', text: I18n.t('groups.samples.index.title')
      assert_samples_table_headers
      assert_select 'table tbody tr', count: 20
      assert_select "table tbody tr##{dom_id(@sample3)} td:nth-child(2)", text: /#{Regexp.escape(@sample3.name)}/
    end

    test 'index paginates the samples table' do
      get group_samples_url(@group, page: 2)

      assert_response :success
      assert_select 'table tbody tr', count: 6
      assert_select "table tbody tr##{dom_id(@sample3)}", count: 0
    end

    test 'index renders the data grid when the flag is enabled' do
      Flipper.enable(:data_grid_samples_table)

      get group_samples_url(@group)

      assert_response :success
      assert_samples_data_grid
    ensure
      Flipper.disable(:data_grid_samples_table)
    end

    test 'index renders samples for a group with linked groups and projects' do
      sign_in users(:david_doe)
      group = groups(:david_doe_group_four)

      get group_samples_url(group)

      assert_response :success
      assert_select 'h1', text: I18n.t('groups.samples.index.title')
      assert_select 'table tbody tr', count: 20
      assert_select "table tbody tr##{dom_id(@sample1)} td:nth-child(2)", text: /#{Regexp.escape(@sample1.name)}/
    end

    test 'workflow execution link visibility by role' do
      [[@user, true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get group_samples_url(@group)

        assert_response :success
        assert_workflow_execution_link(present:, locale: user.locale)
      end
    end

    test 'sample actions dropdown visibility by role' do
      [[@user, true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get group_samples_url(@group)

        assert_response :success
        assert_actions_dropdown(present:, locale: user.locale)
      end
    end

    test 'clone samples action visibility by role' do
      [[@user, true], [users(:ryan_doe), false]].each do |user, present|
        sign_in user

        get group_samples_url(@group)

        assert_response :success
        assert_actions_menu_item('clone', present:, locale: user.locale)
      end
    end

    test 'delete samples action visibility by role' do
      [[@user, true], [users(:joan_doe), false]].each do |user, present|
        sign_in user

        get group_samples_url(@group)

        assert_response :success
        assert_actions_dropdown(present: true, locale: user.locale)
        assert_actions_menu_item('delete_samples', present:, locale: user.locale)
      end
    end

    test 'cannot access group samples without authorization' do
      sign_in users(:user_no_access)

      get group_samples_url(@group)

      assert_response :unauthorized
    end

    test 'quick search filters the samples list by name' do
      get group_samples_url(@group, q: { name_or_puid_cont: 'Sample 1' })

      assert_response :success
      assert_select 'table tbody tr', count: 13
      assert_select "table tbody tr##{dom_id(@sample1)} td:nth-child(2)", text: /#{Regexp.escape(@sample1.name)}/
      assert_select "table tbody tr##{dom_id(@sample2)}", count: 0
    end

    test 'advanced search filters samples by puid using the in operator' do
      sample9 = samples(:sample9)

      get group_samples_url(@group),
          params: samples_advanced_search_params(
            [[{ field: 'puid', operator: 'in', value: [@sample1.puid, @sample2.puid] }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 2
      assert_select "#samples-table table tbody tr##{dom_id(@sample1)}"
      assert_select "#samples-table table tbody tr##{dom_id(@sample2)}"
      assert_select "#samples-table table tbody tr##{dom_id(sample9)}", count: 0
    end

    test 'advanced search filters samples by a metadata field name containing periods' do
      sample28 = samples(:sample28)

      get group_samples_url(@group),
          params: samples_advanced_search_params(
            [[{ field: 'metadata.unique.metadata.field', operator: '=',
                value: sample28.metadata['unique.metadata.field'] }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 1
      assert_select "#samples-table table tbody tr##{dom_id(sample28)}"
      assert_select "#samples-table table tbody tr##{dom_id(@sample1)}", count: 0
    end

    test 'advanced search filters samples using the exists operator' do
      sample28 = samples(:sample28)

      get group_samples_url(@group),
          params: samples_advanced_search_params(
            [[{ field: 'metadata.unique.metadata.field', operator: 'exists' }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 1
      assert_select "#samples-table table tbody tr##{dom_id(sample28)}"
    end

    test 'advanced search rejects a submission without a complete condition' do
      post search_group_samples_url(@group),
           params: samples_advanced_search_params([[{ field: 'name', operator: 'contains', value: '' }]]),
           as: :turbo_stream

      assert_response :unprocessable_content
      assert_match I18n.t('general.form.error_summary.title', count: 1), response.body
    end
  end
end
