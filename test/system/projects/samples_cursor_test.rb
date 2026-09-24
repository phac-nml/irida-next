# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SamplesCursorTest < ApplicationSystemTestCase
    setup do
      skip 'Requires the paired Pathogen cursor release' unless
        Pathogen::DataGridComponent.method_defined?(:virtual_cursor_pagination?)

      @user = users(:john_doe)
      @project = projects(:project1)
      @namespace = groups(:group_one)
      Flipper.enable_actor(:data_grid_samples_table, @user)
      login_as @user
    end

    teardown do
      Flipper.disable(:data_grid_samples_table)
    end

    test 'PUID cells preserve their horizontal padding at wide and narrow widths' do
      samples(:sample1).update!(puid: 'INXT_SAM_A2JXWWWWWW')
      visit namespace_project_samples_url(@namespace, @project)
      assert_selector '#samples-table[data-virtual-ready]'
      assert_selector '[role="gridcell"]', text: 'INXT_SAM_A2JXWWWWWW'

      [1600, 443].each do |width|
        page.current_window.resize_to(width, 1000)
        puid_cell_spacing.each do |spacing|
          assert_operator spacing['left'], :>=, spacing['padding_left'] - 1
          assert_operator spacing['right'], :>=, spacing['padding_right'] - 1
        end
      end
    ensure
      page.current_window.resize_to(1280, 1024)
    end

    test 'keyboard sorting and filtering stay scoped and standard table remains available' do
      visit namespace_project_samples_url(@namespace, @project, limit: 2)
      assert_selector '#project-samples-results [data-pvc-data-grid-pagination-mode="cursor"]'
      # Only two rows are seeded; reaching the third confirms the paired cursor JavaScript is active.
      find('[role="columnheader"]', text: I18n.t('samples.table_component.puid'))
        .send_keys(%i[control end], :down)
      assert_selector '#samples-table [role="row"][data-pvc-data-grid-global-row-index]', count: 3
      assert_selector '#samples-table [role="grid"][aria-rowcount="4"]'
      # This marker must survive each scoped response, which replaces only frame contents.
      page.execute_script('document.querySelector("h1").dataset.cursorTestMarker = "retained"')
      header = find('[role="columnheader"]', text: I18n.t('samples.table_component.puid'))
      header.send_keys(:enter)
      assert_selector 'button[data-sort-field="puid"]:focus'
      find('button[data-sort-field="puid"]').send_keys(:space)
      assert_selector '[role="columnheader"][aria-sort="ascending"] button[data-sort-field="puid"]'
      assert_selector 'button[data-sort-field="puid"]:focus'
      message = I18n.t('projects.samples.cursor.sorted_asc', column: I18n.t('samples.table_component.puid'))
      assert_selector '#project-samples-sort-status', text: message, visible: :all
      assert_selector 'h1[data-cursor-test-marker="retained"]'
      assert_accessible

      within '#project-samples-results' do
        find('input[name="q[name_or_puid_cont]"]').fill_in with: samples(:sample1).puid
        find('input[name="q[name_or_puid_cont]"]').send_keys(:enter)
      end
      assert_selector '#samples-table [role="row"][data-pvc-data-grid-global-row-index]', count: 1
      assert_selector 'h1[data-cursor-test-marker="retained"]'
      assert_accessible
      assert_no_selector '#project-samples-results a[href*="table_view=standard"]'
      visit namespace_project_samples_url(@namespace, @project, table_view: 'standard',
                                                                q: { name_or_puid_cont: samples(:sample1).puid })
      assert_selector '#samples-table[data-samples-table-version="v1"]'
      assert_no_selector 'turbo-frame#project-samples-results'
      assert_selector 'input[name="q[name_or_puid_cont]"]' do |field|
        assert_equal samples(:sample1).puid, field.value
      end
    end

    private

    def puid_cell_spacing
      page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('#samples-table [role="gridcell"][aria-colindex="1"]')).map(cell => {
          const bounds = cell.getBoundingClientRect();
          const content = cell.querySelector('span').getBoundingClientRect();
          const style = getComputedStyle(cell);
          return {
            left: content.left - bounds.left,
            right: bounds.right - content.right,
            padding_left: parseFloat(style.paddingLeft),
            padding_right: parseFloat(style.paddingRight)
          };
        });
      JS
    end
  end
end
