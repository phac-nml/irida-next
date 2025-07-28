# frozen_string_literal: true

require 'test_helper'
require_relative 'component_test_helper'

module Pathogen
  module Pagination
    # Tests for the Pathogen::Pagination::PageSizeSelectComponent
    # This test suite ensures the page size select component renders correctly
    class PageSizeSelectComponentTest < ViewComponent::TestCase
      include ComponentTestHelper

      test 'renders page size select' do
        pagy = mock_pagy
        request = mock_request

        render_inline(PageSizeSelectComponent.new(
                        pagy: pagy,
                        page_sizes: [10, 25, 50],
                        request: request
                      ))

        assert_selector('select#page-size-selector')
        assert_selector('option[value="10"]')
        assert_selector('option[value="25"]')
        assert_selector('option[value="50"]')
        assert_selector('input[type="hidden"][name="page"][value="1"]', visible: :hidden)
      end

      test 'does not render when only one page exists' do
        pagy = mock_pagy(count: 5, items: 10, pages: 1)
        request = mock_request

        render_inline(PageSizeSelectComponent.new(
                        pagy: pagy,
                        page_sizes: [10, 25, 50],
                        request: request
                      ))

        assert_no_selector('select')
      end

      test 'applies correct classes to select element' do
        component = PageSizeSelectComponent.new(
          pagy: mock_pagy,
          page_sizes: [10, 25, 50],
          request: mock_request
        )

        assert_includes(component.send(:select_classes), 'rounded-lg')
        assert_includes(component.send(:select_classes), 'border')
        assert_includes(component.send(:select_classes), 'h-11')
      end
    end
  end
end
