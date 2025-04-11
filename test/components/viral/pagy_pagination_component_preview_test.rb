# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PagyPaginationComponentTest < ViewComponentTestCase
    test 'renders default' do
      render_preview(:default)

      assert_selector 'nav.pagy.nav'
      assert_selector 'li span.cursor-not-allowed', text: I18n.t('viral.pagy.pagination_component.previous')
      assert_selector 'li > a', text: I18n.t('viral.pagy.pagination_component.next')
      assert_selector 'li span.cursor-not-allowed', text: '1', count: 1
      assert_selector 'li > a:not([aria-disabled="true"])', count: 5
    end

    test 'does not render when only one page' do
      render_preview(:only_one_page)

      assert_no_selector 'nav.pagy.nav'
      assert_no_selector 'li span.cursor-not-allowed', text: I18n.t('viral.pagy.pagination_component.previous')
      assert_no_selector 'li span.cursor-not-allowed', text: I18n.t('viral.pagy.pagination_component.next')
      assert_no_selector 'li span.cursor-not-allowed', text: '1'
      assert_no_selector 'li > a:not([aria-disabled="true"])'
    end

    test 'renders many pages' do
      render_preview(:many_pages)

      assert_selector 'nav.pagy.nav'
      assert_selector 'li > a', text: I18n.t('viral.pagy.pagination_component.previous')
      assert_selector 'li > a', text: I18n.t('viral.pagy.pagination_component.next')
      assert_selector 'li span.cursor-not-allowed', text: '5', count: 1
      assert_selector 'li > a:not([aria-disabled="true"])', count: 6
      assert_selector 'li span.cursor-not-allowed', text: '...', count: 2
    end
  end
end
