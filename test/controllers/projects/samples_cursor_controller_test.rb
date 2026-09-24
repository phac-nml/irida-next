# frozen_string_literal: true

require 'test_helper'

module Projects
  class SamplesCursorControllerTest < ActionDispatch::IntegrationTest
    setup do
      skip 'Requires the paired Pathogen cursor release' unless
        Pathogen::DataGridComponent.method_defined?(:virtual_cursor_pagination?)

      sign_in users(:john_doe)
      @project = projects(:project1)
      @namespace = groups(:group_one)
      Flipper.enable_actor(:data_grid_samples_table, users(:john_doe))
    end

    teardown do
      Flipper.disable(:data_grid_samples_table)
    end

    test 'pilot counts the full matching total once before rendering the first cursor batch' do
      statements = sample_selects do
        get namespace_project_samples_path(@namespace, @project), params: { limit: 2 }
      end

      assert_response :success
      assert_select 'turbo-frame#project-samples-results', count: 1
      assert_select '[data-pvc-data-grid-pagination-mode="cursor"][aria-rowcount="4"]', count: 1
      assert_select '[data-pvc-data-grid-total-count="3"]', count: 1
      assert_select '[data-pathogen--data-grid-target="paginationPosition"]', text: 'Rows 1–2 of 3'
      assert_equal 1, statements.grep(/\bCOUNT\s*\(/i).size, statements.join("\n")
      assert statements.none? { |sql| sql.match?(/\bOFFSET\b/i) }, statements.join("\n")
      assert_select 'button[data-sort-field="updated_at"]', count: 1
      assert_select '[role="columnheader"][aria-sort="descending"]', count: 1
      assert_select 'a[href*="table_view=standard"]', count: 0
      assert_select '[data-controller~="launch-workflow"]', count: 0
      assert_select 'input[name="sample_ids[]"]', count: 0
      assert_select '#project-samples-sort-status[role="status"][aria-live="polite"]', count: 1
      assert_select 'turbo-frame #project-samples-sort-status', count: 0
      assert_select '[data-cursor-sort-message="Sorted by Last Updated, descending."]', count: 1
    end

    test 'host importmap serves the paired Pathogen cursor module and current host source' do
      get namespace_project_samples_path(@namespace, @project)
      imports = JSON.parse(css_select('script[type="importmap"]').first.content).fetch('imports')
      assert imports.key?('pathogen_view_components')
      assert_includes Rails.application.config.importmap.cache_sweepers,
                      Pathogen::ViewComponents::Engine.root.join('app/assets/javascripts')
      cursor_asset = imports.fetch('pathogen_view_components/data_grid_controller/cursor_source')
      get cursor_asset
      assert_response :success
      assert_includes response.body, 'CursorRowSource'
      get imports.fetch('controllers/samples_cursor_controller')
      assert_response :success
      assert_includes response.body, 'X-Samples-Cursor-Request'
      get imports.fetch('application')
      assert_response :success
      assert_includes response.body, 'import "controllers"'
    end

    test 'standard table stays available while pilot is enabled' do
      get namespace_project_samples_path(@namespace, @project),
          params: { table_view: 'standard', q: { sort: 'name asc' } }

      assert_response :success
      assert_select '#samples-table[data-samples-table-version="v1"]', count: 1
      assert_select 'turbo-frame#project-samples-results', count: 0
      assert_select 'a[href*="table_view=standard"][href*="name"]', minimum: 1
    end

    test 'cursor rows preserve global indexes and standalone markup' do
      get rows_namespace_project_samples_path(@namespace, @project), params: { limit: 2, q: { sort: 'puid asc' } }

      assert_response :success
      first_page = response.parsed_body
      assert_equal [0, 1], first_page.fetch('rows').pluck('index')
      assert first_page.fetch('next_cursor').present?
      assert_includes first_page.fetch('rows').first.fetch('html'), 'role="row"'
      get rows_namespace_project_samples_path(@namespace, @project),
          params: { limit: 2, cursor: first_page.fetch('next_cursor'), q: { sort: 'puid asc' } }

      assert_response :success
      second_page = response.parsed_body
      assert_equal [2], second_page.fetch('rows').pluck('index')
      assert_nil second_page.fetch('next_cursor')
      assert_includes second_page.fetch('rows').first.fetch('html'), 'aria-rowindex="4"'
    end

    test 'initial total follows the complete filter including no matching rows' do
      get namespace_project_samples_path(@namespace, @project),
          params: { q: { name_or_puid_cont: samples(:sample1).puid } }
      assert_response :success
      assert_select '[data-pvc-data-grid-total-count="1"][aria-rowcount="2"]', count: 1
      assert_select '[data-pathogen--data-grid-target="paginationPosition"]', text: 'Rows 1–1 of 1'

      get namespace_project_samples_path(@namespace, @project),
          params: { q: { name_or_puid_cont: 'no-matching-sample' } }
      assert_response :success
      assert_select '[data-pathogen--data-grid-target="paginationPosition"]', text: 'Rows 0–0 of 0'
      assert_select '[data-pvc-data-grid-global-row-index]', count: 0
    end

    test 'an empty project shows zero alongside its empty-state guidance' do
      project = projects(:john_doe_project3)
      get namespace_project_samples_path(project.namespace.parent, project)

      assert_response :success
      assert_select '.empty_state_message [data-samples-total]', text: 'Samples: 0'
      assert_select '.empty_state_message', text: /There are no samples associated with this project/
    end

    test 'scoped query replacement counts the new matching total once' do
      get namespace_project_samples_path(@namespace, @project), params: { limit: 2 }
      statements = sample_selects do
        post search_namespace_project_samples_path(@namespace, @project),
             params: { q: { name_or_puid_cont: samples(:sample1).puid } }, as: :turbo_stream
      end

      assert_response :success
      assert_select 'turbo-stream[target="project-samples-results"]', count: 1
      assert_select '[data-pathogen--data-grid-target="paginationPosition"]', text: 'Rows 1–1 of 1'
      assert_equal 1, statements.grep(/\bCOUNT\s*\(/i).size, statements.join("\n")
    end

    test 'initial and subsequent row endpoints remain free of count and offset queries' do
      statements = sample_selects do
        get rows_namespace_project_samples_path(@namespace, @project), params: { limit: 2, q: { sort: 'puid asc' } }
        assert_response :success
        cursor = response.parsed_body.fetch('next_cursor')
        get rows_namespace_project_samples_path(@namespace, @project),
            params: { limit: 2, cursor:, q: { sort: 'puid asc' } }
      end

      assert_response :success
      assert_equal [2], response.parsed_body.fetch('rows').pluck('index')
      assert(statements.any? { |sql| sql.include?('pvc_cursor_value') })
      assert statements.none? { |sql| sql.match?(/\bCOUNT\s*\(|\bOFFSET\b/i) }, statements.join("\n")
    end

    test 'row request cannot overwrite the stored project query' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { sort: 'name desc' } }
      get rows_namespace_project_samples_path(@namespace, @project), params: { q: { sort: 'puid asc' } }
      assert_response :success
      get namespace_project_samples_path(@namespace, @project)

      assert_select '[role="columnheader"][aria-sort="descending"] button[data-sort-field="name"]', count: 1
    end

    test 'invalid cursor and query return explicit recoverable errors' do
      get rows_namespace_project_samples_path(@namespace, @project), params: { cursor: 'tampered' }
      assert_response :unprocessable_content
      assert_equal 'invalid_cursor', response.parsed_body.fetch('error')

      get rows_namespace_project_samples_path(@namespace, @project), params: { q: { sort: 'unknown desc' } }
      assert_response :unprocessable_content
      assert_equal 'invalid_query', response.parsed_body.fetch('error')
    end

    test 'a cursor from the previous sort cannot populate the new query' do
      get rows_namespace_project_samples_path(@namespace, @project), params: { limit: 1, q: { sort: 'name asc' } }
      cursor = response.parsed_body.fetch('next_cursor')
      get rows_namespace_project_samples_path(@namespace, @project),
          params: { limit: 1, cursor:, q: { sort: 'name desc' } }

      assert_response :unprocessable_content
      assert_equal 'invalid_cursor', response.parsed_body.fetch('error')
    end

    test 'invalid initial query renders validation instead of starting a cursor chain' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { sort: 'invalid asc' } }

      assert_response :unprocessable_content
      assert_select 'turbo-frame#project-samples-results', count: 1
      assert_select '[data-pvc-data-grid-pagination-mode="cursor"]', count: 0
    end

    test 'filter changes replace only the scoped results' do
      post search_namespace_project_samples_path(@namespace, @project),
           params: { q: { name_or_puid_cont: 'Sample', sort: 'name asc' } },
           headers: { 'X-Samples-Cursor-Request' => 'latest-filter' }, as: :turbo_stream

      assert_response :success
      assert_select 'turbo-stream[target="project-samples-results"][data-cursor-request-id="latest-filter"]', count: 1
      assert_select 'turbo-stream[action="refresh"]', count: 0
    end

    test 'project-unsupported initial and submitted sorts render a clear validation error' do
      get namespace_project_samples_path(@namespace, @project), params: { q: { sort: 'namespaces.puid asc' } }
      assert_response :unprocessable_content
      assert_select '[role="alert"]', text: I18n.t('projects.samples.cursor.invalid_query')
      assert_select '[data-pvc-data-grid-pagination-mode="cursor"]', count: 0
      post search_namespace_project_samples_path(@namespace, @project),
           params: { q: { sort: 'namespaces.puid asc' } },
           headers: { 'X-Samples-Cursor-Request' => 'invalid-filter' }, as: :turbo_stream
      assert_response :unprocessable_content
      assert_select 'turbo-stream[target="table-filter"][data-cursor-request-id="invalid-filter"]', count: 1
      assert_select 'turbo-stream[target="project-samples-results"]', count: 0
    end

    test 'scoped frame responses echo query identity and metadata forms target the same result scope' do
      get namespace_project_samples_path(@namespace, @project),
          headers: { 'Turbo-Frame' => 'project-samples-results', 'X-Samples-Cursor-Request' => 'latest-sort' }
      assert_response :success
      assert_select 'turbo-frame#project-samples-results[data-cursor-request-id="latest-sort"]', count: 1
      get list_namespace_project_metadata_templates_path(@namespace, @project),
          params: { metadata_template: 'all', table_view: 'cursor' }
      assert_response :success
      assert_select 'form[data-turbo-frame="project-samples-results"]', count: 1
    end

    test 'older Pathogen releases retain the existing V2 table without cursor wiring' do
      Projects::SamplesController.any_instance.stubs(:cursor_library_available?).returns(false)
      get namespace_project_samples_path(@namespace, @project)

      assert_response :success
      assert_select '#samples-table[data-samples-table-version="v2"] table', count: 1
      assert_select 'turbo-frame#project-samples-results', count: 0
      get rows_namespace_project_samples_path(@namespace, @project)
      assert_response :not_found
    end

    test 'cursor sort links reset the frame with the complete current filter' do
      get namespace_project_samples_path(@namespace, @project),
          params: { limit: 2, q: { name_or_puid_cont: 'Sample', sort: 'name desc', metadata_template: 'all' } }
      assert_response :success
      button = css_select('button[data-sort-field="puid"]').first
      sort_params = Rack::Utils.parse_nested_query(URI.parse(button['data-sort-url']).query)
      assert_equal 'puid asc', sort_params.dig('q', 'sort')
      assert_equal 'Sample', sort_params.dig('q', 'name_or_puid_cont')
      assert_equal 'all', sort_params.dig('q', 'metadata_template')
      assert_nil sort_params['cursor']
      get button['data-sort-url'], headers: { 'Turbo-Frame' => 'project-samples-results' }
      assert_response :success
      assert_select 'turbo-frame#project-samples-results [aria-sort="ascending"] button[data-sort-field="puid"]'
    end

    test 'row endpoint is unavailable when pilot is disabled' do
      Flipper.disable(:data_grid_samples_table)
      get rows_namespace_project_samples_path(@namespace, @project)
      assert_response :not_found
    end

    test 'row endpoint authorizes every request' do
      sign_in users(:david_doe)
      Flipper.enable_actor(:data_grid_samples_table, users(:david_doe))
      project = projects(:john_doe_project2)
      get rows_namespace_project_samples_path(namespaces_user_namespaces(:john_doe_namespace), project)
      assert_response :unauthorized
    end

    private

    def sample_selects(&)
      statements = []
      subscriber = ->(_name, _start, _finish, _id, payload) { statements << payload[:sql] }
      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record', &)
      statements.select { |sql| sql.match?(/\ASELECT\b/i) && sql.match?(/\bFROM\s+"samples"/i) }
    end
  end
end
