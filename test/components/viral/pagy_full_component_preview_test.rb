# frozen_string_literal: true

require 'application_system_test_case'

class PagyFullComponentPreviewTest < ApplicationSystemTestCase
  test 'renders default' do
    visit('/rails/view_components/viral_pagy_full_component/default')

    assert_selector 'nav.pagy.nav'
    assert_selector 'li a[aria-disabled="true"]', text: 'Previous'
    assert_selector 'li > a', text: 'Next'
    assert_selector 'li a[aria-disabled="true"]', text: '1'
    assert_selector 'li > a:not([aria-disabled="true"])', count: '5'
  end

  test 'renders empty state' do
    visit('/rails/view_components/viral_pagy_full_component/empty_state')

    assert_selector 'h1', text: I18n.t('components.viral.pagy.empty_state.title')
    assert_selector 'p', text: I18n.t('components.viral.pagy.empty_state.description')
    assert_no_selector 'nav.pagy.nav'
  end
end
