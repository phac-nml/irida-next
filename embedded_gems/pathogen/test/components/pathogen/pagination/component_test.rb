# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Pagination
    # Tests for the Pathogen::Pagination::Component
    # This test suite covers various scenarios including rendering modes,
    # page size selection, and edge cases.
    class ComponentTest < ViewComponent::TestCase
      def test_renders_simple_mode
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 10)
        render_inline(Component.new(pagy: pagy, mode: :simple))

        assert_selector "nav[role='navigation']"
        assert_selector "select[name='page-size']"
        assert_selector "button[data-action*='previousPage']"
        assert_selector "button[data-action*='nextPage']"
        assert_no_selector "input[name='page']"
        assert_no_selector "a[data-action*='goToPage']"
      end

      def test_renders_full_mode
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 10)
        render_inline(Component.new(pagy: pagy, mode: :full))

        assert_selector "nav[role='navigation']"
        assert_selector "select[name='page-size']"
        assert_selector "button[data-action*='previousPage']"
        assert_selector "button[data-action*='nextPage']"
        assert_selector "input[name='page']"
        assert_selector "a[data-action*='goToPage']"
      end

      def test_does_not_render_with_zero_items
        pagy = mock_pagy(count: 0, page: 1, pages: 0, items: 10)
        render_inline(Component.new(pagy: pagy))

        assert_no_selector "nav[role='navigation']"
      end

      def test_disables_previous_button_on_first_page
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 10)
        render_inline(Component.new(pagy: pagy))

        assert_selector "button[data-action*='previousPage'][disabled]"
        assert_no_selector "button[data-action*='nextPage'][disabled]"
      end

      def test_disables_next_button_on_last_page
        pagy = mock_pagy(count: 100, page: 10, pages: 10, items: 10)
        render_inline(Component.new(pagy: pagy))

        assert_no_selector "button[data-action*='previousPage'][disabled]"
        assert_selector "button[data-action*='nextPage'][disabled]"
      end

      def test_renders_custom_page_sizes
        pagy = mock_pagy(count: 100, page: 1, pages: 10, items: 20)
        render_inline(Component.new(pagy: pagy, page_sizes: [20, 40, 60]))

        assert_selector "select[name='page-size'] option", count: 3
        assert_selector "select[name='page-size'] option[selected]", text: '20'
      end

      private

      def mock_pagy(count:, page:, pages:, items:)
        pagy = Minitest::Mock.new
        pagy.expect :count, count
        pagy.expect :page, page
        pagy.expect :pages, pages
        pagy.expect :items, items
        pagy.expect :from, ((page - 1) * items) + 1
        pagy.expect :to, [page * items, count].min
        pagy.expect :prev, page > 1 ? page - 1 : nil
        pagy.expect :next, page < pages ? page + 1 : nil
        pagy.expect :series, (1..pages).to_a
        pagy
      end
    end
  end
end
