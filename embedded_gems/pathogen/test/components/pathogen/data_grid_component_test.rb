# frozen_string_literal: true

require 'view_component_test_case'

module Pathogen
  # Tests for Pathogen::DataGridComponent rendering behavior.
  class DataGridComponentTest < ViewComponentTestCase
    test 'renders grid with caption and sticky columns' do
      render_inline(Pathogen::DataGridComponent.new(
                      caption: 'Sample grid',
                      sticky_columns: 1,
                      rows: [
                        { id: 'S-001', name: 'Sample one' },
                        { id: 'S-002', name: 'Sample two' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, width: 120)
        grid.with_column('Name', key: :name, width: 200)
      end

      assert_selector '.pathogen-data-grid__table[aria-labelledby]'
      assert_selector '.pathogen-data-grid__caption', text: 'Sample grid'
      assert_no_selector '.pathogen-data-grid--multi-sticky'
      assert_selector 'th.pathogen-data-grid__cell--header'
      assert_selector 'th.pathogen-data-grid__cell--sticky[style*="--pathogen-data-grid-sticky-left: 0px"]'
      assert_selector 'td.pathogen-data-grid__cell--body', text: 'Sample one'
    end

    test 'adds multi sticky class when more than one sticky column is active' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 2,
                      rows: [
                        { id: 'S-050', name: 'Sample fifty', status: 'Active' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, width: 120)
        grid.with_column('Name', key: :name, width: 220)
        grid.with_column('Status', key: :status)
      end

      assert_selector '.pathogen-data-grid.pathogen-data-grid--multi-sticky'
    end

    test 'does not render caption or aria-labelledby without caption' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-001', name: 'Sample one' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, width: 120)
        grid.with_column('Name', key: :name, width: 200)
      end

      assert_no_selector '.pathogen-data-grid__caption'
      assert_no_selector '.pathogen-data-grid__table[aria-labelledby]'
    end

    test 'does not apply sticky when width is missing' do
      render_inline(Pathogen::DataGridComponent.new(
                      caption: 'Grid without widths',
                      sticky_columns: 1,
                      rows: [
                        { id: 'S-010', name: 'Sample zero' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id)
        grid.with_column('Name', key: :name)
      end

      assert_no_selector 'th.pathogen-data-grid__cell--sticky'
    end

    test 'renders custom cell blocks and defaults to key lookup' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-003', name: 'Sample three' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id)
        grid.with_column('Name') { |row| ActionController::Base.helpers.content_tag(:strong, row[:name]) }
      end

      assert_selector 'td.pathogen-data-grid__cell--body', text: 'S-003'
      assert_selector 'strong', text: 'Sample three'
    end

    test 'applies sticky left offset when provided without width' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-020', name: 'Sample twenty' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, sticky: true, sticky_left: 24)
        grid.with_column('Name', key: :name)
      end

      assert_selector 'th.pathogen-data-grid__cell--sticky[style*="--pathogen-data-grid-sticky-left: 24px"]'
    end

    test 'accepts sticky left offset values with CSS units' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-022', name: 'Sample twenty-two' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, sticky: true, sticky_left: 'calc(10ch + 8px)')
        grid.with_column('Name', key: :name)
      end

      assert_selector 'th.pathogen-data-grid__cell--sticky[style*="--pathogen-data-grid-sticky-left: calc(10ch + 8px)"]'
    end

    test 'normalizes numeric widths to px units' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-021', name: 'Sample twenty-one' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, width: 96)
        grid.with_column('Name', key: :name, width: '180px')
      end

      assert_selector 'th[style*="--pathogen-data-grid-col-width: 96px"]'
      assert_selector 'th[style*="--pathogen-data-grid-col-width: 180px"]'
    end

    test 'renders custom header content when provided' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-030', name: 'Sample thirty' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id, header_content: -> { 'Custom ID' })
        grid.with_column('Name', key: :name)
      end

      assert_selector 'th', text: 'Custom ID'
      assert_selector 'th', text: 'Name'
    end

    test 'renders empty state when rows are blank' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: []
                    )) do |grid|
        grid.with_column('ID', key: :id)
        grid.with_empty_state { 'No rows' }
      end

      assert_selector '.pathogen-data-grid__scroll', text: 'No rows'
      assert_no_selector '.pathogen-data-grid__table'
    end

    test 'renders live region, metadata warning, and footer slots outside scroll container' do
      render_inline(Pathogen::DataGridComponent.new(
                      sticky_columns: 0,
                      rows: [
                        { id: 'S-040', name: 'Sample forty' }
                      ]
                    )) do |grid|
        grid.with_column('ID', key: :id)
        grid.with_live_region do
          ActionController::Base.helpers.content_tag(:div, 'Live region', class: 'test-live-region')
        end
        grid.with_metadata_warning do
          ActionController::Base.helpers.content_tag(:div, 'Warning', class: 'test-metadata-warning')
        end
        grid.with_footer do
          ActionController::Base.helpers.content_tag(:div, 'Footer', class: 'test-footer')
        end
      end

      assert_selector '.pathogen-data-grid > .test-live-region'
      assert_selector '.pathogen-data-grid > .test-metadata-warning'
      assert_selector '.pathogen-data-grid > .pathogen-data-grid__scroll + .test-footer'
      assert_selector '.pathogen-data-grid > .test-live-region + .test-metadata-warning + .pathogen-data-grid__scroll'
      assert_no_selector '.pathogen-data-grid__scroll .test-live-region'
      assert_no_selector '.pathogen-data-grid__scroll .test-metadata-warning'
      assert_no_selector '.pathogen-data-grid__scroll .test-footer'
    end
  end
end
