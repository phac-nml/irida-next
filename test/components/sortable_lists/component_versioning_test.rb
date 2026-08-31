# frozen_string_literal: true

require 'view_component_test_case'

module SortableLists
  class ComponentVersioningTest < ViewComponentTestCase
    AVAILABLE_LIST_ARGS = {
      id: 'available-list',
      title: 'Available',
      list_role: :available,
      counterpart_list_id: 'selected-list',
      list_items: %w[Alpha Beta]
    }.freeze

    SELECTED_LIST_ARGS = {
      id: 'selected-list',
      title: 'Selected',
      list_role: :selected,
      counterpart_list_id: 'available-list',
      list_items: %w[One Two],
      required: true
    }.freeze

    test 'renders v1 by default' do
      render_component

      assert_selector 'ul#available-list[role="listbox"][aria-multiselectable="true"]'
      assert_selector 'ul#selected-list[role="listbox"][aria-multiselectable="true"]'
      assert_selector 'li[role="option"]', count: 4
      assert_no_selector 'input[type="checkbox"]'
    end

    test 'still renders v1 by default when feature flag is enabled during phased rollout' do
      Flipper.enable(:v2_sortable_lists)
      render_component

      assert_selector 'ul#available-list[role="listbox"][aria-multiselectable="true"]'
      assert_selector 'ul#selected-list[role="listbox"][aria-multiselectable="true"]'
      assert_selector 'li[role="option"]', count: 4
      assert_no_selector 'input[type="checkbox"]'
    end

    test 'renders v1 when version override is v1' do
      render_component(version: :v1)

      assert_selector 'ul#available-list[role="listbox"]'
      assert_selector 'ul#selected-list[role="listbox"]'
      assert_no_selector 'input[type="checkbox"]'
    end

    test 'renders v2 when version override is v2' do
      render_component(version: :v2)

      assert_selector 'ul#available-list input[type="checkbox"]', count: 2
      assert_selector 'ul#selected-list input[type="checkbox"]', count: 2
      assert_no_selector 'ul[role="listbox"]'
    end

    test 'raises when version override is invalid' do
      assert_raises(ArgumentError) do
        render_component(version: :v3)
      end
    end

    private

    def render_component(version: nil)
      render_inline SortableListsComponent.new(version:) do |sortable_lists|
        sortable_lists.with_list(**AVAILABLE_LIST_ARGS)
        sortable_lists.with_list(**SELECTED_LIST_ARGS)
      end
    end
  end
end
