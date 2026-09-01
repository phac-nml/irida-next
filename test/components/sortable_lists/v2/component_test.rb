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

      test 'renders action controls as aria-disabled rather than natively disabled' do
        component = SortableListsComponent.new(version: :v2)
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: %w[Alpha Beta]
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: ['One']
        )

        render_inline(component)

        assert_selector 'button[aria-disabled="true"]', minimum: 4
        assert_no_selector 'button[disabled]'
      end

      test 'labels each action group and links its keyboard instructions' do
        component = SortableListsComponent.new(version: :v2)
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: ['Alpha']
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: ['One']
        )

        render_inline(component)

        instructions_text = I18n.t('components.sortable_lists.v2.component.keyboard_instructions')
        instructions = page.find('p.sr-only', text: instructions_text)
        available_label = I18n.t('components.sortable_lists.v2.list_component.actions', title: 'Available')
        selected_label = I18n.t('components.sortable_lists.v2.list_component.actions', title: 'Selected')

        assert_selector "[role='group'][aria-label='#{available_label}'][aria-describedby='#{instructions[:id]}']"
        assert_selector "[role='group'][aria-label='#{selected_label}'][aria-describedby='#{instructions[:id]}']"
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

        assert_selector 'ul#available-list[data-required="false"]'
        assert_no_selector '#available-list-required'
        assert_selector 'ul#selected-list[data-required="true"]'
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
        assert_selector 'ul#list span', text: 'One'
        assert_no_selector "[data-sortable-lists--v2--two-lists-selection-target='ariaLiveUpdate']"
      end

      test 'renders title and description when provided' do
        component = SortableListsComponent.new(
          version: :v2,
          title: 'Fields',
          description: 'Choose metadata fields'
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

        assert_selector 'div', text: 'Fields'
        assert_selector 'div', text: 'Choose metadata fields'
      end

      test 'allows a list to opt out of interactive controls' do
        component = SortableListsComponent.new(version: :v2)
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: ['Alpha'],
          interactive: false
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: ['One']
        )

        render_inline(component)

        assert_no_selector 'ul#available-list input[type="checkbox"]'
        assert_selector 'ul#available-list span', text: 'Alpha'
        assert_no_selector '[data-sortable-lists--v2--two-lists-selection-target="addButton"]'
        assert_selector 'ul#selected-list input[type="checkbox"]', count: 1
        assert_selector 'button', text: I18n.t('common.actions.remove')
      end

      test 'infers list roles and counterpart ids from available and selected list ids' do
        component = SortableListsComponent.new(version: :v2)
        component.with_list(id: 'available-list', title: 'Available', list_items: ['Alpha'])
        component.with_list(id: 'selected-list', title: 'Selected', list_items: ['One'])

        render_inline(component)

        assert_selector(
          "button[aria-controls~='available-list'][aria-controls~='selected-list']",
          text: I18n.t('components.sortable_lists.v2.list_component.add')
        )
        assert_selector(
          "button[aria-controls~='available-list'][aria-controls~='selected-list']",
          text: I18n.t('common.actions.remove')
        )
      end

      test 'includes describedby references on v2 lists' do
        component = SortableListsComponent.new(version: :v2, required: true)
        component.with_list(
          id: 'available-list',
          title: 'Available',
          list_role: :available,
          counterpart_list_id: 'selected-list',
          list_items: ['One'],
          describedby: 'available-help'
        )
        component.with_list(
          id: 'selected-list',
          title: 'Selected',
          list_role: :selected,
          counterpart_list_id: 'available-list',
          list_items: ['Two'],
          describedby: 'selected-help fields-error'
        )

        render_inline(component)

        assert_selector 'ul#available-list[aria-describedby*="available-help"]'
        assert_selector 'ul#selected-list[aria-describedby*="selected-help"]'
        assert_selector 'ul#selected-list[aria-describedby*="fields-error"]'
        assert_selector 'ul#selected-list[aria-describedby*="selected-list-required"]'
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
