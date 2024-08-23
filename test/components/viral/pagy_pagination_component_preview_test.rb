# frozen_string_literal: true

require 'application_system_test_case'

class PagyPaginationComponentPreviewTest < ApplicationSystemTestCase
  test 'renders default' do
    visit('/rails/view_components/viral_pagy_pagination_component/default')

    assert_selector 'nav.pagy.nav'
    assert_selector 'li button[disabled]', text: 'Previous'
    assert_selector 'li > a', text: 'Next'
    assert_selector 'li button[disabled]', text: '1'
    assert_selector 'li > a:not([data-aria-disabled="true"])', count: '5'
  end

  test 'renders with one item' do
    visit('/rails/view_components/viral_pagy_pagination_component/only_one_page')

    assert_selector 'nav.pagy.nav'
    assert_selector 'li button[disabled]', text: 'Previous'
    assert_selector 'li button[disabled]', text: 'Next'
    assert_selector 'li button[disabled]', text: '1'
    assert_no_selector 'li > a:not([data-aria-disabled="true"])'
  end

  test 'renders many pages' do
    visit('/rails/view_components/viral_pagy_pagination_component/many_pages')

    assert_selector 'nav.pagy.nav'
    assert_selector 'li > a', text: 'Previous'
    assert_selector 'li > a', text: 'Next'
    assert_selector 'li button[disabled]', text: '5'
    assert_selector 'li > a:not([data-aria-disabled="true"])', count: '6'
    assert_selector 'li button[disabled]', text: '...', count: '2'
  end
end
