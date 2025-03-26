# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class PagyPaginationComponentTest < ViewComponentTestCase
    test 'renders default' do
      render_preview(:default)

      assert_selector 'nav.pagy.nav'
      assert_selector 'li a[aria-disabled="true"]', text: 'Previous'
      assert_selector 'li > a', text: 'Next'
      assert_selector 'li a[aria-disabled="true"]', text: '1'
      assert_selector 'li > a:not([aria-disabled="true"])', count: '5'
    end

    test 'does not render when only one page' do
      render_preview(:only_one_page)

      assert_no_selector 'nav.pagy.nav'
      assert_no_selector 'li a[aria-disabled="true"]', text: 'Previous'
      assert_no_selector 'li a[aria-disabled="true"]', text: 'Next'
      assert_no_selector 'li a[aria-disabled="true"]', text: '1'
      assert_no_selector 'li > a:not([aria-disabled="true"])'
    end

    test 'renders many pages' do
      render_preview(:many_pages)

      assert_selector 'nav.pagy.nav'
      assert_selector 'li > a', text: 'Previous'
      assert_selector 'li > a', text: 'Next'
      assert_selector 'li a[aria-disabled="true"]', text: '5'
      assert_selector 'li > a:not([aria-disabled="true"])', count: '6'
      assert_selector 'li a[aria-disabled="true"]', text: '...', count: '2'
    end
  end
end
