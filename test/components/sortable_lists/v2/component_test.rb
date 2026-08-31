# frozen_string_literal: true

require 'view_component_test_case'

module SortableLists
  module V2
    class ComponentTest < ViewComponentTestCase
      test 'renders v2 preview with checkbox list controls' do
        component = SortableListsComponent.new(version: :v2)
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: %w[Alpha Beta Gamma Delta]
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: %w[One Two Three]
        )

        render_inline(component)

        assert_selector 'ul#available-list input[type="checkbox"]', count: 4
        assert_selector 'ul#selected-list input[type="checkbox"]', count: 3
        assert_selector 'button', text: I18n.t('components.sortable_lists.v2.list_component.add')
        assert_selector 'button', text: I18n.t('common.actions.remove')
      end

      test 'renders required semantics for selected list in v2' do
        component = SortableListsComponent.new(version: :v2, required: true)
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: ['One']
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: ['Two']
        )

        render_inline(component)

        assert_selector 'ul#available-list[aria-required="false"]'
        assert_no_selector '#available-list-required'
        assert_selector 'ul#selected-list[aria-required="true"]'
        assert_selector '#selected-list-required'
      end

      test 'does not render interactive controls when v2 is noninteractive' do
        component = SortableListsComponent.new(
          version: :v2,
          interactive: false,
          templates: [{ id: 'template-one', name: 'Template one', fields: ['One'] }],
          template_label: 'Template'
        )
        component.with_list(id: 'list', title: 'Static', list_items: ['One'])

        render_inline(component)

        assert_no_selector 'select#template-selector'
        assert_no_selector 'input[type="checkbox"]'
        assert_no_selector "[data-sortable-lists--v2--two-lists-selection-target='ariaLiveUpdate']"
      end

      test 'uses an instance-scoped template selector id and links label correctly' do
        component = SortableListsComponent.new(
          version: :v2,
          templates: [{ id: 'template-one', name: 'Template one', fields: ['One'] }],
          template_label: 'Template'
        )
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: ['One']
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: ['Two']
        )

        render_inline(component)

        selector = page.find('select')

        assert_not_equal 'template-selector', selector[:id]
        assert_selector "label[for='#{selector[:id]}']", text: 'Template'
      end
    end
  end
end
