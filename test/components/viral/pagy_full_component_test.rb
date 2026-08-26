# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PagyFullComponentTest < ViewComponentTestCase
    test 'renders default' do
      render_preview(:default)

      assert_selector 'nav.pagy.nav'
      assert_selector 'li span.cursor-not-allowed', text: I18n.t('components.viral.pagy.pagination_component.previous')
      assert_selector 'li > a', text: I18n.t('components.viral.pagy.pagination_component.next')
      assert_selector 'li span.cursor-not-allowed', text: I18n.t('components.viral.pagy.pagination_component.previous')
      assert_selector 'li a[aria-current="page"]', text: '1', count: 1
      assert_selector 'li > a', count: '6'
    end

    test 'renders empty state' do
      render_preview(:empty_state)

      assert_selector 'h2', text: I18n.t('components.viral.pagy.empty_state.title')
      assert_selector 'span', text: I18n.t('components.viral.pagy.empty_state.description')
      assert_no_selector 'nav.pagy.nav'
    end
  end
end
