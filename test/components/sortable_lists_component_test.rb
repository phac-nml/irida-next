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

  test 'renders three lists preview with one independent list' do
    render_preview(:three_lists)

    assert_selector "[data-controller='sortable-lists--v1--two-lists-selection']"
    assert_selector 'ul#available-list'
    assert_selector 'ul#selected-list'
    assert_selector 'ul#review-list li', count: 3
  end

  test 'renders standalone three lists preview without sortable controller wiring' do
    render_preview(:three_lists_without_grouping)

    assert_no_selector "[data-controller='sortable-lists--v1--two-lists-selection']"
    assert_selector 'ul#first-list li', count: 4
    assert_selector 'ul#second-list li', count: 3
    assert_selector 'ul#third-list li', count: 3
  end
end
