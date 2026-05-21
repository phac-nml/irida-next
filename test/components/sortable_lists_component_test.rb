# frozen_string_literal: true

require 'view_component_test_case'

class SortableListsComponentTest < ViewComponentTestCase
  test 'renders default preview' do
    render_preview(:default)

    assert_selector 'ul#list li', count: 4
  end

  test 'renders two lists preview with sortable controller wiring' do
    render_preview(:two_lists)

    assert_selector "[data-controller='sortable-lists--v1--two-lists-selection']"
    assert_selector 'ul#available-list li', count: 4
    assert_selector 'ul#selected-list li', count: 3
    assert_selector 'button', text: I18n.t('components.sortable_lists.v1.list_component.add')
    assert_selector 'button', text: I18n.t('common.actions.remove')
  end

  test 'renders APG multi-select listbox markup' do
    render_preview(:two_lists)

    assert_selector 'p[id^="sortable-lists-v1-instructions"]'
    assert_selector 'ul#available-list[role="listbox"][tabindex="0"][aria-multiselectable="true"]'
    assert_selector 'ul#selected-list[role="listbox"][tabindex="0"][aria-multiselectable="true"]'
    assert_selector 'ul#available-list[aria-labelledby="available-list-list-label"]'
    assert_selector 'ul#selected-list[aria-labelledby="selected-list-list-label"]'
    assert_selector 'ul#available-list[aria-describedby]'
    assert_selector 'ul#selected-list[aria-describedby]'
    assert_no_selector 'ul[role="listbox"][aria-activedescendant]', visible: :all

    assert_selector 'ul#available-list li[role="option"][id][tabindex="-1"][aria-selected="false"]', count: 4
    assert_selector 'ul#selected-list li[role="option"][id][tabindex="-1"][aria-selected="false"]', count: 3
    assert_no_selector 'li[role="option"] a, li[role="option"] button, li[role="option"] input'
  end

  test 'renders contextual list labels and describedby references' do
    component = SortableListsComponent.new(required: true)
    component.with_list(
      id: 'available-list',
      title: 'Not imported',
      list_items: ['One'],
      describedby: 'metadata-guidance-available-description'
    )
    component.with_list(
      id: 'selected-list',
      title: 'Will be imported',
      list_items: ['Two'],
      required: true,
      describedby: 'metadata-guidance-selected-description metadata_fields_error'
    )

    render_inline(component)

    assert_selector '#available-list-list-label', text: 'Not imported'
    assert_selector '#selected-list-list-label', text: 'Will be imported'
    assert_selector 'ul#available-list[aria-describedby*="metadata-guidance-available-description"]'
    assert_selector 'ul#selected-list[aria-describedby*="metadata-guidance-selected-description"]'
    assert_selector 'ul#selected-list[aria-describedby*="metadata_fields_error"]'
    assert_selector 'ul#selected-list[aria-describedby*="selected-list-required"]'
  end

  test 'renders required state only on the selected listbox' do
    component = SortableListsComponent.new(required: true)
    component.with_list(id: 'available-list', title: 'Available', list_items: ['One'])
    component.with_list(id: 'selected-list', title: 'Selected', list_items: [])

    render_inline(component)

    assert_selector 'ul#available-list[aria-required="false"]'
    assert_selector 'ul#available-list[aria-describedby^="sortable-lists-v1-instructions"]'
    assert_no_selector '#available-list-required'
    assert_selector 'ul#selected-list[aria-required="true"]'
    assert_selector '#selected-list-required'
    assert_selector 'ul#selected-list[aria-describedby*="selected-list-required"]'
  end

  test 'renders action buttons with controls, shortcuts, and aria disabled state' do
    render_preview(:two_lists)

    assert_selector 'div[role="group"][aria-label]', count: 2
    assert_selector(
      "button[aria-controls~='available-list'][aria-controls~='selected-list'][aria-disabled='true']" \
      "[aria-keyshortcuts='#{I18n.t('components.sortable_lists.v1.list_component.keyboard_shortcuts.add')}']",
      text: I18n.t('components.sortable_lists.v1.list_component.add')
    )
    assert_selector(
      "button[aria-controls~='available-list'][aria-controls~='selected-list'][aria-disabled='true']" \
      "[aria-keyshortcuts='#{I18n.t('components.sortable_lists.v1.list_component.keyboard_shortcuts.remove')}']",
      text: I18n.t('common.actions.remove')
    )
    assert_selector(
      "button[aria-controls='selected-list'][aria-disabled='true']" \
      "[aria-keyshortcuts='#{I18n.t('components.sortable_lists.v1.list_component.keyboard_shortcuts.up')}']",
      text: I18n.t('components.sortable_lists.v1.list_component.up')
    )
    assert_selector(
      "button[aria-controls='selected-list'][aria-disabled='true']" \
      "[aria-keyshortcuts='#{I18n.t('components.sortable_lists.v1.list_component.keyboard_shortcuts.down')}']",
      text: I18n.t('components.sortable_lists.v1.list_component.down')
    )
  end

  test 'renders three lists preview with one independent list' do
    render_preview(:three_lists)

    assert_selector "[data-controller='sortable-lists--v1--two-lists-selection']"
    assert_selector 'ul#available-list[role="listbox"]'
    assert_selector 'ul#selected-list[role="listbox"]'
    assert_selector 'ul#review-list li', count: 3
    assert_no_selector 'ul#review-list[role="listbox"]'
  end

  test 'renders standalone three lists preview without sortable controller wiring' do
    render_preview(:three_lists_without_grouping)

    assert_no_selector "[data-controller='sortable-lists--v1--two-lists-selection']"
    assert_selector 'ul#first-list li', count: 4
    assert_selector 'ul#second-list li', count: 3
    assert_selector 'ul#third-list li', count: 3
    assert_no_selector 'ul[role="listbox"]'
    assert_no_selector 'button[aria-keyshortcuts]'
  end

  test 'does not render template selector wiring for noninteractive lists' do
    component = SortableListsComponent.new(
      interactive: false,
      templates: [{ id: 'template-one', name: 'Template one', fields: ['One'] }],
      template_label: 'Template'
    )
    component.with_list(id: 'static-list', title: 'Static', list_items: ['One'])

    render_inline(component)

    assert_no_selector 'select#template-selector'
    assert_no_selector '[aria-controls=""]', visible: :all
  end
end
