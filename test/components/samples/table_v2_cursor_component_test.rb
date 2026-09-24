# frozen_string_literal: true

require 'test_helper'

module Samples
  class TableV2CursorComponentTest < ViewComponent::TestCase
    setup do
      skip 'Requires the paired Pathogen cursor release' unless
        Pathogen::DataGridComponent.method_defined?(:virtual_cursor_pagination?)
    end

    test 'cursor headers expose one current sort and preserve the complete query' do
      with_request_url '/group-1/project-1/-/samples' do
        render_inline Table::V2::Component.new(
          [samples(:sample1)], projects(:project1).namespace, nil,
          metadata_fields: ['collection date'],
          search_params: { 'sort' => 'metadata_collection date desc', 'name_or_puid_cont' => 'Sample' },
          virtual_pagination: { mode: :cursor, rows_url: '/rows.json', next_cursor: 'next', page_size: 100 }
        )

        assert_selector '[role="grid"][aria-rowcount="-1"]'
        assert_selector '[role="columnheader"][aria-sort]', count: 1
        assert_selector '[aria-sort="descending"] button[data-sort-field="metadata_collection date"]'
        assert_selector '[role="columnheader"][data-pathogen--data-grid-has-interactive="true"]', count: 6
        assert_selector 'button[data-sort-field].font-semibold', count: 6
        assert_selector '[data-pvc-data-grid-lane="pinned"] [role="columnheader"]', count: 1
        button = page.find('button[data-sort-field="metadata_collection date"]', visible: :all)
        query = Rack::Utils.parse_nested_query(URI.parse(button['data-sort-url']).query)
        assert_equal 'metadata_collection date asc', query.dig('q', 'sort')
        assert_equal 'Sample', query.dig('q', 'name_or_puid_cont')
        assert_selector 'a[data-turbo-frame="_top"]', text: samples(:sample1).name
      end
    end

    test 'standalone row uses the same fixed columns and global row index' do
      with_request_url '/group-1/project-1/-/samples' do
        render_inline Table::V2::RowComponent.new(samples(:sample1), projects(:project1).namespace,
                                                  global_row_index: 100, metadata_fields: ['collection date'])
        assert_selector '[role="row"][aria-rowindex="102"][data-pvc-data-grid-global-row-index="100"]'
        assert_selector '[role="gridcell"]', count: 6
        assert_selector '[data-pvc-data-grid-lane="pinned"] [role="gridcell"]', count: 1
      end
    end

    test 'ordinary V2 remains a regular grid without cursor controls' do
      with_request_url '/-/groups/group-1/-/samples' do
        render_inline Table::V2::Component.new([samples(:sample1)], groups(:group_one), nil)
        assert_selector 'table', count: 1
        assert_no_selector '[data-pvc-data-grid-pagination-mode]'
        assert_no_selector 'button[data-sort-field]'
      end
    end
  end
end
