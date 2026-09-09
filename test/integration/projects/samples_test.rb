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

    # Successful advanced search is exercised through GET on the index (the bookmarkable q-params
    # entrypoint); validation failures go through the POST search action that renders a turbo_stream.
    test 'advanced search filters samples by a metadata field' do
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field: 'metadata.metadatafield1', operator: '=', value: sample30.metadata['metadatafield1'] }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 1
      assert_select "#samples-table table tbody tr##{dom_id(sample30)}"
      assert_select "#samples-table table tbody tr##{dom_id(@sample1)}", count: 0
    end

    test 'advanced search filters samples using multiple conditions in a group' do
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field: 'metadata.metadatafield1', operator: '=', value: sample30.metadata['metadatafield1'] },
              { field: 'metadata.metadatafield2', operator: '=', value: sample30.metadata['metadatafield2'] }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 1
      assert_select "#samples-table table tbody tr##{dom_id(sample30)}"
    end

    test 'advanced search filters samples using multiple groups' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field: 'name', operator: '=', value: @sample1.name }],
             [{ field: 'name', operator: '=', value: sample2.name }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 2
      assert_select "#samples-table table tbody tr##{dom_id(@sample1)}"
      assert_select "#samples-table table tbody tr##{dom_id(sample2)}"
      assert_select "#samples-table table tbody tr##{dom_id(sample30)}", count: 0
    end

    test 'advanced search renders results messages' do
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field: 'name', operator: 'contains', value: 'no-such-sample-zzz' }]]
          )
      assert_response :success
      assert_select '[role="status"]', text: I18n.t('components.search.advanced.results_message.zero')

      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field: 'metadata.metadatafield1', operator: '=', value: sample30.metadata['metadatafield1'] }]]
          )
      assert_response :success
      assert_select '[role="status"]', text: I18n.t('components.search.advanced.results_message.singular')

      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field: 'name', operator: 'contains', value: 'ample' }]]
          )
      assert_response :success
      assert_select '[role="status"]',
                    text: I18n.t('components.search.advanced.results_message.plural', total_count: 3)
    end

    test 'advanced search rejects a submission without a complete condition' do
      post search_namespace_project_samples_url(@namespace, @project),
           params: samples_advanced_search_params([[{ field: 'name', operator: 'contains', value: '' }]]),
           as: :turbo_stream

      assert_response :unprocessable_content
      assert_match I18n.t('general.form.error_summary.title', count: 1), response.body
    end

    test 'advanced search rejects duplicate fields within a group' do
      sample30 = samples(:sample30)

      post search_namespace_project_samples_url(@namespace, @project),
           params: samples_advanced_search_params(
             [[{ field: 'metadata.metadatafield1', operator: 'contains', value: sample30.metadata['metadatafield1'] },
               { field: 'metadata.metadatafield1', operator: 'contains', value: sample30.metadata['metadatafield1'] }]]
           ),
           as: :turbo_stream

      assert_response :unprocessable_content
      assert_match I18n.t('activemodel.errors.models.advanced_search_condition.attributes.field.taken'),
                   response.body
    end
  end

  # Metadata-typed advanced search coverage shares the metadata_doe fixtures, so it lives in a
  # dedicated class whose setup signs in and resolves the metadata namespace/project once.
  class MetadataSamplesTest < ActionDispatch::IntegrationTest
    include ActionView::RecordIdentifier

    setup do
      sign_in users(:metadata_doe)
      @namespace = groups(:group_metadata)
      @project = projects(:projectMetadata)
      @sample62 = samples(:sample62)
    end

    test 'advanced search filters samples between metadata dates' do
      target_date = Date.parse(@sample62.metadata['example_date'])

      assert_between_filter(field: 'metadata.example_date', operators: %w[>= <=],
                            low: (target_date - 1).to_s, high: (target_date + 1).to_s)
    end

    test 'advanced search filters samples between metadata dates using metadata operators' do
      Flipper.enable(:advanced_search_metadata_operators)
      target_date = Date.parse(@sample62.metadata['example_date'])

      assert_between_filter(field: 'metadata.example_date',
                            operators: %w[date_greater_than_equals date_less_than_equals],
                            low: (target_date - 1).to_s, high: (target_date + 1).to_s)
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
    end

    test 'advanced search filters samples between metadata floats' do
      target_float = @sample62.metadata['example_float'].to_f

      assert_between_filter(field: 'metadata.example_float', operators: %w[>= <=],
                            low: target_float - 0.1, high: target_float + 0.1)
    end

    test 'advanced search filters samples between metadata floats using metadata operators' do
      Flipper.enable(:advanced_search_metadata_operators)
      target_float = @sample62.metadata['example_float'].to_f

      assert_between_filter(field: 'metadata.example_float',
                            operators: %w[numeric_greater_than_equals numeric_less_than_equals],
                            low: target_float - 0.1, high: target_float + 0.1)
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
    end

    test 'advanced search filters samples between metadata integers' do
      target_integer = @sample62.metadata['example_integer'].to_i

      assert_between_filter(field: 'metadata.example_integer', operators: %w[>= <=],
                            low: target_integer - 1, high: target_integer + 1)
    end

    private

    # Asserts a two-condition "between" advanced search on @project returns only @sample62.
    def assert_between_filter(field:, operators:, low:, high:)
      get namespace_project_samples_url(@namespace, @project),
          params: samples_advanced_search_params(
            [[{ field:, operator: operators.first, value: low },
              { field:, operator: operators.last, value: high }]]
          )

      assert_response :success
      assert_select '#samples-table table tbody tr', count: 1
      assert_select "#samples-table table tbody tr##{dom_id(@sample62)}"
    end
  end
end
