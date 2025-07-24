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
        @system_arguments[:data] ||= {}
        @system_arguments[:data][:turbo_action] = 'replace'
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

      # @return [String] Classes for the page size select dropdown
      def page_size_select_classes
        class_names(
          'rounded-lg border border-slate-300 bg-white px-3 py-2 pr-8 text-sm text-slate-700 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500',
          'dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300 dark:focus:border-primary-500 dark:focus:ring-primary-500'
        )
      end

      # @return [String] Classes for the page number input (jump to page)
      def page_number_input_classes
        class_names(
          'w-20 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500',
          'dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300 dark:focus:border-primary-500 dark:focus:ring-primary-500'
        )
      end

      # @return [String] Classes for the pagination link (unselected page)
      def pagination_link_classes(is_first:, is_last:, prev_is_gap:, next_is_selected:)
        class_names(
          'flex items-center justify-center text-slate-700 bg-white border border-slate-300 font-medium text-sm px-4 h-11 hover:bg-slate-100 hover:text-slate-900',
          'dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700 dark:hover:bg-slate-700 dark:hover:text-slate-100',
          { 'rounded-s-lg' => is_first, 'rounded-e-lg' => is_last, 'border-l-0' => !is_first || prev_is_gap,
            'border-r-0' => next_is_selected }
        )
      end

      # @return [String] Classes for the selected page span
      def pagination_selected_classes(is_first:, is_last:)
        class_names(
          'flex items-center justify-center px-4 h-11 ms-0 leading-tight border border-primary-600 bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-200 font-bold text-sm cursor-default',
          { 'rounded-s-lg' => is_first, 'rounded-e-lg' => is_last }
        )
      end

      # @return [String] Classes for the gap/ellipsis span
      # Only apply the left border if this is not the first item and show_left is true (prevents double border)
      def pagination_gap_classes(is_first:, is_last:, show_left:, show_right:)
        class_names(
          'flex items-center justify-center px-4 h-11 ms-0 leading-tight border-t border-b border-slate-300 dark:border-slate-700 text-slate-600 bg-slate-100 dark:bg-slate-800 dark:text-slate-400 cursor-default',
          { 'border-l border-slate-300 dark:border-slate-700' => !is_first && show_left,
            'border-r border-slate-300 dark:border-slate-700' => show_right, 'rounded-s-lg' => is_first, 'rounded-e-lg' => is_last }
        )
      end

      # @return [String] Classes for the label and info text
      def info_text_classes
        class_names('text-sm text-slate-700 dark:text-slate-300')
      end
    end
  end
end
