# frozen_string_literal: true

require 'test_helper'
require_relative 'component_test_helper'

module Pathogen
  module Pagination
    # Tests for the Pathogen::Pagination::PageInfoComponent
    # This test suite ensures the page info component renders correctly with item counts and names
    # and applies the correct CSS classes.
    class PageInfoComponentTest < ViewComponent::TestCase
      include ComponentTestHelper

      test 'renders page info with item count' do
        pagy = mock_pagy(count: 100, items: 10, page: 1)

        render_inline(PageInfoComponent.new(pagy: pagy, item_name: 'item'))

        assert_text('1 - 10 of 100 items')
      end

      test 'renders singular item name' do
        pagy = mock_pagy(count: 1, items: 1, page: 1)

        render_inline(PageInfoComponent.new(pagy: pagy, item_name: 'item'))

        assert_text('1 - 1 of 1 item')
      end

      test 'applies correct text classes' do
        component = PageInfoComponent.new(
          pagy: mock_pagy,
          item_name: 'item'
        )

        assert_includes(component.send(:info_text_classes), 'text-sm')
        assert_includes(component.send(:info_text_classes), 'text-slate-700')
        assert_includes(component.send(:info_text_classes), 'dark:text-slate-300')
      end

      test 'does not render when no items' do
        pagy = mock_pagy(count: 0, items: 10, page: 1)

        render_inline(PageInfoComponent.new(pagy: pagy, item_name: 'item'))

        assert_no_text('of 0 items')
      end
    end
  end
end
