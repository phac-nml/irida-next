# frozen_string_literal: true

require 'test_helper'
require_relative 'component_test_helper'

module Pathogen
  module Pagination
    class PageLinksComponentTest < ViewComponent::TestCase
      include ComponentTestHelper

      test 'renders pagination links' do
        pagy = mock_pagy
        request = mock_request
        
        render_inline(PageLinksComponent.new(pagy: pagy, request: request))
        
        assert_selector('nav.pagy')
        assert_selector('ul.inline-flex')
        assert_selector('a[data-turbo-stream="true"]', text: '1')
        assert_selector('a[data-turbo-stream="true"]', text: '2')
        assert_selector('a[rel="next"]', text: 'Next')
      end

      test 'does not render when only one page exists' do
        pagy = mock_pagy(count: 5, items: 10, pages: 1)
        request = mock_request
        
        render_inline(PageLinksComponent.new(pagy: pagy, request: request))
        
        assert_no_selector('nav.pagy')
      end

      test 'generates correct page URLs' do
        pagy = mock_pagy
        request = mock_request
        component = PageLinksComponent.new(pagy: pagy, request: request)
        
        assert_includes(component.send(:page_url, 2), 'page=2')
        assert_includes(component.send(:page_url, 2), 'limit=10')
      end

      test 'applies correct classes for pagination elements' do
        # Test the class methods directly
        link_classes = PageLinksComponent.pagination_link_classes(
          is_first: true,
          is_last: false,
          prev_is_gap: false,
          next_is_selected: false
        )
        
        assert_includes(link_classes, 'rounded-s-lg')
        assert_includes(link_classes, 'dark:bg-slate-800')
        
        selected_classes = PageLinksComponent.pagination_selected_classes(
          is_first: true,
          is_last: false
        )
        
        assert_includes(selected_classes, 'bg-primary-100')
        assert_includes(selected_classes, 'dark:bg-primary-900')
        
        gap_classes = PageLinksComponent.pagination_gap_classes(
          is_first: false,
          is_last: false,
          show_left: true,
          show_right: true
        )
        
        assert_includes(gap_classes, 'border-t')
        assert_includes(gap_classes, 'border-b')
      end
    end
  end
end
