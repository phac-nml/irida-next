# frozen_string_literal: true

module Pathogen
  module Pagination
    # Main pagination component that provides a complete pagination interface
    # with page size selection, navigation, and jump-to functionality.
    class Component < Pathogen::Component
      # Constants for pagination modes
      MODE_OPTIONS = %i[simple full].freeze
      DEFAULT_MODE = :full

      # Constants for page size options
      DEFAULT_PAGE_SIZES = [10, 25, 50, 100].freeze

      # @param pagy [Pagy] The pagy instance for pagination
      # @param mode [Symbol] The pagination mode (:simple or :full)
      # @param page_sizes [Array<Integer>] Available page sizes
      # @param item_name [String] The name of the items being paginated (e.g., "items", "records")
      # @param system_arguments [Hash] Additional arguments to be passed to the component
      def initialize(pagy:, mode: DEFAULT_MODE, page_sizes: DEFAULT_PAGE_SIZES, item_name: 'items', **system_arguments)
        @pagy = pagy
        @mode = fetch_or_fallback(MODE_OPTIONS, mode, DEFAULT_MODE)
        @page_sizes = page_sizes
        @item_name = item_name
        @system_arguments = system_arguments
      end

      # @return [Boolean] Whether the component should render
      def render?
        @pagy.count.positive?
      end

      private

      attr_reader :pagy, :mode, :page_sizes, :item_name, :system_arguments

      # Helper methods for ARIA attributes and translations
      def aria_label
        t('.aria_label')
      end

      def aria_live
        'polite'
      end

      def navigation_aria_label
        t('.navigation_aria_label')
      end

      # @return [String] The current page range text
      def page_range_text
        t('.page_range',
          from: pagy.from,
          to: pagy.to,
          count: pagy.count,
          item_name: item_name.pluralize(pagy.count))
      end

      # @return [String] The current page size text
      def page_size_text
        t('.page_size',
          size: pagy.vars[:items],
          item_name: item_name.pluralize(pagy.vars[:items]))
      end

      # @return [String] The current page text
      def current_page_text
        t('.current_page',
          page: pagy.page,
          pages: pagy.pages)
      end
    end
  end
end
