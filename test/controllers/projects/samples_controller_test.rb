# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @sample1 = samples(:sample1)
      @sample23 = samples(:sample23)
      @project = projects(:project1)
      @namespace = groups(:group_one)
    end

    test 'should get index where member in parent group' do
      get namespace_project_samples_url(@namespace, @project)
      assert_response :success

      w3c_validate 'Project Samples Page'
    end

    test 'should get index where project is under user\'s namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)

      get namespace_project_samples_url(namespace, project)
      assert_response :success
    end

    test 'should get new' do
      get new_namespace_project_sample_url(@namespace, @project)
      assert_response :success
    end

    test 'should search' do
      post search_namespace_project_samples_url(@namespace, @project),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: 'Sample 1' } } } } } },
           as: :turbo_stream
      assert_response :success
    end

    test 'should not search with invalid query' do
      post search_namespace_project_samples_url(@namespace, @project),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: '' } } } } } },
           as: :turbo_stream
      assert_response :unprocessable_content
    end

    test 'should create sample' do
      assert_difference('Sample.count') do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: 'New Sample'
             } },
             as: :turbo_stream
      end

      assert_redirected_to namespace_project_sample_url(id: Sample.last.id)
    end

    test 'should not create a sample with short sample name parameter' do
      assert_difference -> { Sample.count } => 0,
                        -> { @namespace.reload.samples_count } => 0,
                        -> { @project.reload.samples_count } => 0 do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: '?'
             } }
      end
      assert_response :unprocessable_content
    end

    test 'should not create a sample with same sample name parameter' do
      assert_difference -> { Sample.count } => 0,
                        -> { @namespace.reload.samples_count } => 0,
                        -> { @project.reload.samples_count } => 0 do
        post namespace_project_samples_url(@namespace, @project),
             params: { sample: {
               description: @sample1.description,
               name: 'Project 1 Sample 1'
             } }
      end
      assert_response :unprocessable_content
    end

    test 'should show sample when user is a member of a parent group of the project' do
      get namespace_project_sample_url(@namespace, @project, @sample1)
      assert_response :success
    end

    test 'should show sample when project is in user\'s namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      sample = samples(:sample24)

      get namespace_project_sample_url(namespace, project, sample)
      assert_response :success
    end

    test 'should not show sample for a member who does not have access to the project' do
      sign_in users(:david_doe)
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      sample = samples(:sample24)

      get namespace_project_sample_url(namespace, project, sample)
      assert_response :unauthorized
    end

    test 'should not show sample, if it does not belong to the project' do
      get namespace_project_sample_url(@namespace, @project, @sample23)
      assert_response :not_found
    end

    test 'should get edit' do
      get edit_namespace_project_sample_url(@namespace, @project, @sample1)
      assert_response :success
    end

    test 'should update sample in which the user is a member in a parent group with a role >= Maintainer' do
      patch namespace_project_sample_url(@namespace, @project, @sample1),
            params: { sample: { description: @sample1.description, name: 'New Sample Name',
                                project_id: @sample1.project_id } },
            as: :turbo_stream
      assert_redirected_to namespace_project_sample_url(@namespace, @project, @sample1)
    end

    test 'should update sample in which the the project is in the user\'s namespace' do
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project2)
      sample = samples(:sample24)

      patch namespace_project_sample_url(namespace, project, sample),
            params: { sample: { description: sample.description, name: 'New Sample Name',
                                project_id: sample.project_id } },
            as: :turbo_stream
      assert_redirected_to namespace_project_sample_url(namespace, project, sample)
    end

    test 'should not update a sample with wrong parameters' do
      patch namespace_project_sample_url(@namespace, @project, @sample1),
            params: { sample: { description: @sample1.description, name: '?',
                                project_id: @sample1.project_id } }

      assert_response :unprocessable_content
    end

    test 'show sample history listing' do
      @sample1.create_logidze_snapshot!

      get namespace_project_sample_path(@namespace, @project, @sample1, tab: 'history')

      assert_response :success
    end

    test 'view sample history version' do
      @sample1.create_logidze_snapshot!

      get namespace_project_sample_view_history_version_path(@namespace, @project, @sample1, version: 1,
                                                                                             format: :turbo_stream)

      assert_response :success
    end

    test 'should list samples' do
      post list_samples_path(format: :turbo_stream), params: {
        page: 1,
        sample_ids: [@sample1.id],
        list_class: 'sample'
      }
      assert_response :success
    end

    test 'should handle metadata template none' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { metadata_template: 'none' } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('turbo-frame[src*="metadata_template=none"]')
    end

    test 'should handle metadata template all' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { metadata_template: 'all' } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('turbo-frame[src*="metadata_template=all"]')
    end

    test 'should apply default sort and support sorting project samples' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)

      # default sort: updated_at desc (most recently updated first)
      get namespace_project_samples_url(@namespace, @project)
      assert_response :success
      assert_first_rows_include(@sample1.name, sample2.name, row_scope: '#samples-table-body')

      # sort by name asc
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'name asc' } }
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_first_rows_include(@sample1.name, sample2.name, row_scope: '#samples-table-body')

      # sort by name desc
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'name desc' } }
      assert_response :success
      assert_sort_state(2, 'descending')
      assert_first_rows_include(sample30.name, sample2.name, row_scope: '#samples-table-body')

      # sort by puid asc
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'puid asc' } }
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@sample1.puid, sample2.puid, row_scope: '#samples-table-body')

      # sort by puid desc
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'puid desc' } }
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(sample30.puid, sample2.puid, row_scope: '#samples-table-body')

      # sort by created_at asc (oldest first)
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'created_at asc' } }
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(sample30.name, sample2.name, row_scope: '#samples-table-body')

      # sort by created_at desc (newest first)
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'created_at desc' } }
      assert_response :success
      assert_sort_state(3, 'descending')
      assert_first_rows_include(@sample1.name, sample2.name, row_scope: '#samples-table-body')

      # sort by updated_at asc (oldest first)
      get namespace_project_samples_url(@namespace, @project), params: { q: { sort: 'updated_at asc' } }
      assert_response :success
      assert_sort_state(4, 'ascending')
      assert_first_rows_include(sample30.name, sample2.name, row_scope: '#samples-table-body')
    end

    test 'should apply sort semantics to filtered project samples' do
      sample2 = samples(:sample2)

      get namespace_project_samples_url(@namespace, @project),
          params: { q: { name_or_puid_cont: 'Sample 2', sort: 'puid desc' }, limit: 50 }

      assert_response :success
      assert_sort_state(1, 'descending')

      rendered_puids = rendered_sample_puids
      assert_includes rendered_puids, sample2.puid
      assert_includes rendered_puids, samples(:sample30).puid
      assert_not_includes rendered_puids, @sample1.puid

      rendered_puids.each_cons(2) do |left, right|
        assert_operator left, :>=, right
      end
    end

    test 'should filter project samples by name' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: { q: { name_or_puid_cont: @sample1.name } }

      assert_response :success
      assert_includes rendered_sample_puids, @sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid
      assert_not_includes rendered_sample_puids, sample30.puid
    end

    test 'should filter project samples by puid' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: { q: { name_or_puid_cont: sample2.puid } }

      assert_response :success
      assert_not_includes rendered_sample_puids, @sample1.puid
      assert_includes rendered_sample_puids, sample2.puid
      assert_not_includes rendered_sample_puids, sample30.puid
    end

    test 'should persist quick-search sort state across requests via session' do
      sample2 = samples(:sample2)

      get namespace_project_samples_url(@namespace, @project),
          params: { q: { name_or_puid_cont: @sample1.puid, sort: 'name asc' } }
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_includes rendered_sample_puids, @sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid

      get namespace_project_samples_url(@namespace, @project)
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_includes rendered_sample_puids, @sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid
    end

    test 'should persist quick-search filter state across requests via session' do
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)

      get namespace_project_samples_url(@namespace, @project),
          params: { q: { name_or_puid_cont: @sample1.name } }
      assert_response :success
      assert_equal @sample1.name, rendered_search_field_value
      assert_includes rendered_sample_puids, @sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid
      assert_not_includes rendered_sample_puids, sample30.puid

      get namespace_project_samples_url(@namespace, @project)
      assert_response :success
      assert_equal @sample1.name, rendered_search_field_value
      assert_includes rendered_sample_puids, @sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid
      assert_not_includes rendered_sample_puids, sample30.puid
    end

    test 'should clear metadata sort when metadata template is none' do
      get namespace_project_samples_url(@namespace, @project),
          params: { q: { metadata_template: 'all', sort: 'metadata_metadatafield1 asc' } }

      assert_response :success
      assert_sort_state(6, 'ascending')

      get namespace_project_samples_url(@namespace, @project),
          params: { q: { metadata_template: 'none' } }

      assert_response :success
      assert_sort_state(4, 'descending')
      assert_equal 'updated_at desc', session["samples_#{@project.id}_search_params"]['sort']
    end

    test 'accessing samples index on invalid page causes pagy overflow redirect at project level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_samples_path(@namespace, @project, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end

    test 'POST query_v2 returns 404 when advanced_search_v2 flag is off' do
      Flipper.disable(:advanced_search_v2)
      post query_namespace_project_samples_path(@namespace, @project),
           params: { query_v2: '{"combinator":"and","nodes":[]}' },
           as: :turbo_stream
      assert_response :not_found
    end

    test 'POST query_v2 returns 200 when advanced_search_v2 flag is on with valid query' do
      Flipper.enable(:advanced_search_v2)
      post query_namespace_project_samples_path(@namespace, @project),
           params: { query_v2: '{"combinator":"and","nodes":[]}' },
           as: :turbo_stream
      assert_response :ok
    end

    test 'POST query_v2 returns 422 for invalid json' do
      Flipper.enable(:advanced_search_v2)
      post query_namespace_project_samples_path(@namespace, @project),
           params: { query_v2: '{bad json' },
           as: :turbo_stream
      assert_response :unprocessable_content
    end

    private

    def rendered_sample_puids
      doc = Nokogiri::HTML(response.body)
      doc.css('#samples-table table tbody tr th:first-child').map { |node| node.text.strip }
    end

    def rendered_search_field_value
      doc = Nokogiri::HTML(response.body)
      doc.at_css('input[data-test-selector="search-field-input"]')['value']
    end
  end
end
