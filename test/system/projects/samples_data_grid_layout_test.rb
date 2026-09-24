# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesDataGridLayoutTest < ApplicationSystemTestCase
    setup do
      @user = users(:john_doe)
      @project = projects(:project1)
      @namespace = groups(:group_one)
      fields = %w[AGE COUNTRY FOOD GENDER PATIENT_AGE PATIENT_SEX]
      @project.namespace.update!(metadata_summary: fields.index_with { 1 })
      Flipper.enable_actor(:data_grid_samples_table, @user)
      Projects::SamplesController.any_instance.stubs(:cursor_library_available?).returns(false)
      login_as @user
    end

    teardown do
      Flipper.disable(:data_grid_samples_table)
      page.current_window.resize_to(1280, 1024)
    end

    test 'narrow metadata grid scrolls pinned columns away and keeps keyboard edges visible after resizing' do
      page.current_window.resize_to(443, 900)
      visit namespace_project_samples_url(@namespace, @project, q: { metadata_template: 'all' })
      assert_selector '#samples-table table[role="grid"]'
      assert_selector '#samples-table thead th', count: 11

      before = grid_geometry(scroll_left: 0)
      after = grid_geometry(scroll_left: 200)
      assert_operator after['scroll_left'], :>, 100
      before['pinned_offsets'].zip(after['pinned_offsets']).each do |initial, scrolled|
        assert_in_delta after['scroll_left'], initial - scrolled, 2
      end

      find('#samples-table thead th:first-child').send_keys(:end)
      assert_selector '#samples-table thead th:last-child:focus'
      assert_focused_cell_visible
      find('#samples-table thead th:last-child').send_keys(:home)
      assert_selector '#samples-table thead th:first-child:focus'
      assert_focused_cell_visible

      page.current_window.resize_to(1280, 1000)
      before = grid_geometry(scroll_left: 0)
      after = grid_geometry(scroll_left: 200)
      assert_operator after['container_width'], :>=, 768
      assert_operator after['scroll_left'], :>, 0
      before['pinned_offsets'].zip(after['pinned_offsets']).each do |initial, scrolled|
        assert_in_delta initial, scrolled, 2
      end
    end

    private

    def assert_focused_cell_visible
      geometry = grid_geometry
      assert_operator geometry['focused_left'], :>=, geometry['visible_left'] - 1
      assert_operator geometry['focused_right'], :<=, geometry['visible_right'] + 1
    end

    def grid_geometry(scroll_left: nil) # rubocop:disable Metrics/MethodLength
      page.evaluate_script(<<~JS, scroll_left)
        ((scrollLeft) => {
          const root = document.querySelector('#samples-table');
          const scroll = root.querySelector('[data-pathogen--data-grid-target~="scrollContainer"]');
          if (scrollLeft !== null) scroll.scrollLeft = scrollLeft;
          const bounds = scroll.getBoundingClientRect();
          const focused = document.activeElement.getBoundingClientRect();
          return {
            scroll_left: scroll.scrollLeft,
            container_width: bounds.width,
            pinned_offsets: Array.from(root.querySelectorAll('tbody tr:first-child > *'))
              .slice(0, 2).map(cell => cell.getBoundingClientRect().left - bounds.left),
            focused_left: focused.left,
            focused_right: focused.right,
            visible_left: Math.max(0, bounds.left),
            visible_right: Math.min(window.innerWidth, bounds.right)
          };
        })(arguments[0]);
      JS
    end
  end
end
