# frozen_string_literal: true

require 'test_helper'
require_relative 'component_test_helper'

module Pathogen
  module Pagination
    # Tests for the Pathogen::Pagination::Component
    # This test suite ensures the main component renders correctly with subcomponents
    class ComponentTest < ViewComponent::TestCase
      include ComponentTestHelper

      setup do
        @request = mock_request
      end

      test 'renders in simple mode' do
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 10)
        
        render_inline(Component.new(
          pagy: pagy,
          mode: :simple,
          request: @request
        ))
        
        assert_selector("nav[role='navigation']")
        assert_selector("select[name='limit']")
        assert_selector("a[data-turbo-stream='true']", text: '1')
        assert_selector("a[rel='next']", text: 'Next')
        assert_no_selector("input[name='page']")
      end

      test 'renders in full mode' do
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 10)
        
        render_inline(Component.new(
          pagy: pagy,
          mode: :full,
          request: @request
        ))
        
        assert_selector("nav[role='navigation']")
        assert_selector("select[name='limit']")
        assert_selector("a[data-turbo-stream='true']", text: '1')
        assert_selector("a[rel='next']", text: 'Next')
        assert_selector("input[name='page']")
      end

      test 'does not render with zero items' do
        pagy = mock_pagy(count: 0, page: 1, pages: 0, items: 10)
        
        render_inline(Component.new(
          pagy: pagy,
          request: @request
        ))
        
        assert_no_selector "nav[role='navigation']"
      end

      test 'renders custom page sizes' do
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 20)
        
        render_inline(Component.new(
          pagy: pagy,
          page_sizes: [20, 40, 60],
          request: @request
        ))
        
        assert_selector("select[name='limit'] option[value='20']")
        assert_selector("select[name='limit'] option[value='40']")
        assert_selector("select[name='limit'] option[value='60']")
        assert_selector("select[name='limit'] option[selected][value='20']")
      end

      test 'delegates class methods to PageLinksComponent' do
        assert_respond_to Component, :pagination_link_classes
        assert_respond_to Component, :pagination_selected_classes
        assert_respond_to Component, :pagination_gap_classes
      end
    end
  end
end
