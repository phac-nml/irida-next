# frozen_string_literal: true

require_relative 'page_links_component'
require_relative 'page_size_select_component'
require_relative 'page_info_component'
require_relative 'jump_to_component'

module Pathogen
  module Pagination
    # Main pagination component that provides a complete pagination interface
    # with page size selection, navigation, and jump-to functionality.
    # This component composes several smaller, focused components for better maintainability.
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
        super(**system_arguments)

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

      # Delegate class methods to appropriate subcomponents
      def pagination_link_classes(**args)
        PageLinksComponent.pagination_link_classes(**args)
      end

      def pagination_selected_classes(**args)
        PageLinksComponent.pagination_selected_classes(**args)
      end

      def pagination_gap_classes(**args)
        PageLinksComponent.pagination_gap_classes(**args)
      end
    end
  end
end
