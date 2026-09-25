# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesCursorLayoutTest < ApplicationSystemTestCase
    setup do
      skip 'Requires the paired Pathogen cursor release' unless
        Pathogen::DataGridComponent.method_defined?(:virtual_cursor_pagination?)

      @user = users(:john_doe)
      Flipper.enable_actor(:data_grid_samples_table, @user)
      login_as @user
    end

    teardown do
      Flipper.disable(:data_grid_samples_table)
      page.current_window.resize_to(1280, 1024)
    end

    test 'pinned and scrolling sort buttons fill their headers and preserve keyboard focus' do
      project = projects(:project1)
      visit namespace_project_samples_url(project.namespace.parent, project)
      assert_selector '#samples-table[data-virtual-ready]'

      %w[puid name].each do |field|
        header = find(sort_header(field))
        bounds = header_bounds(header)
        %w[left top right bottom].each { |edge| assert_in_delta 0, bounds[edge], 1 }
        # Click empty space at the header's far edge, beyond its label and icon.
        header.click(x: (bounds['width'] / 2) - 4, y: 0, offset: :center)
        assert_selector %(#{sort_header(field)}[aria-sort="ascending"])
        assert_selector %(button[data-sort-field="#{field}"]:focus)
      end

      find('button[data-sort-field="name"]').send_keys(:escape)
      assert_selector "#{sort_header('name')}:focus"
      find(sort_header('name')).send_keys(:enter)
      assert_selector 'button[data-sort-field="name"]:focus-visible'
      focus = find('button[data-sort-field="name"]').evaluate_script(<<~JS)
        (() => {
          const style = getComputedStyle(this);
          return { offset: parseFloat(style.outlineOffset), width: parseFloat(style.outlineWidth) };
        })();
      JS
      assert_equal(-2, focus['offset'])
      assert_operator focus['width'], :>=, 2

      find('button[data-sort-field="name"]').send_keys(:space)
      assert_selector %(#{sort_header('name')}[aria-sort="descending"])
      assert_selector 'button[data-sort-field="name"]:focus'
      find('button[data-sort-field="name"]').send_keys(:enter)
      assert_selector %(#{sort_header('name')}[aria-sort="ascending"])
      assert_selector 'button[data-sort-field="name"]:focus'
    end

    test 'long results fill the padded page and short results remain compact across viewport sizes' do
      project = projects(:project38)
      page.current_window.resize_to(1600, 1800)
      visit namespace_project_samples_url(project.namespace.parent, project)
      assert_selector '#samples-table[data-virtual-ready] [data-pvc-data-grid-page-size="20"]'
      # The fixture has 200 samples; row 21 must be fetched without manually scrolling.
      assert_selector '#samples-table [data-pvc-data-grid-global-row-index="20"]',
                      text: samples(:bulk_sample21).name
      tall = page_geometry
      assert_in_delta tall['content_bottom'], tall['grid_bottom'], 2
      assert_operator tall['padding_bottom'], :>, 0
      assert_operator tall['grid_height'], :>, 1000

      [[443, 900], [550, 400]].each do |width, height|
        page.current_window.resize_to(width, height)
        find('#main-content').scroll_to(:bottom)
        assert_footer_visible
      end

      page.current_window.resize_to(1600, 1800)
      filter = find('#project-samples-results input[name="q[name_or_puid_cont]"]')
      filter.fill_in with: samples(:bulk_sample200).puid
      filter.send_keys(:enter)
      assert_selector '#samples-table [role="row"][data-pvc-data-grid-global-row-index]', count: 1
      assert_selector '#samples-table [data-pvc-data-grid-total-count="1"]'
      short = page_geometry
      assert_operator short['grid_height'], :<, tall['grid_height'] / 2
      assert_operator short['grid_bottom'], :<, short['content_bottom'] - 100
      assert_footer_visible
    end

    private

    def sort_header(field)
      %(#samples-table [role="columnheader"]:has(button[data-sort-field="#{field}"]))
    end

    def header_bounds(header)
      header.evaluate_script(<<~JS)
        (() => {
          const cell = this.getBoundingClientRect();
          const button = this.querySelector('button').getBoundingClientRect();
          return { left: button.left - cell.left, top: button.top - cell.top,
            right: cell.right - button.right, bottom: cell.bottom - button.bottom,
            width: cell.width, height: cell.height };
        })();
      JS
    end

    def page_geometry
      page.evaluate_script(<<~JS)
        (() => {
          const main = document.querySelector('#main-content');
          const grid = document.querySelector('#samples-table').getBoundingClientRect();
          const padding = parseFloat(getComputedStyle(main).paddingBottom);
          return { content_bottom: main.getBoundingClientRect().bottom - padding,
            padding_bottom: padding, grid_bottom: grid.bottom, grid_height: grid.height };
        })();
      JS
    end

    def assert_footer_visible
      assert_selector '#samples-table [data-pathogen--data-grid-target="paginationPosition"]' do |footer|
        footer.evaluate_script(<<~JS)
          (() => {
            const bounds = this.getBoundingClientRect();
            const main = document.querySelector('#main-content').getBoundingClientRect();
            return bounds.top >= Math.max(0, main.top) - 1 &&
              bounds.bottom <= Math.min(window.innerHeight, main.bottom) + 1;
          })();
        JS
      end
    end
  end
end
