# frozen_string_literal: true

module Pathogen
  module Pagination
    # Component that displays pagination information (e.g., "1-10 of 50 items").
    # This component is used internally by the main Pagination component.
    #
    # @example Basic usage
    #   <%= render PageInfoComponent.new(
    #     pagy: @pagy,
    #     item_name: 'items'
    #   ) %>
    #
    # @see Pathogen::Pagination::Component
    class PageInfoComponent < Pathogen::Component
      # @param pagy [Pagy] The pagy instance for pagination
      # @param item_name [String] The name of the items being paginated (e.g., "items", "records")
      def initialize(pagy:, item_name: 'items', **system_arguments)
        super(**system_arguments)

        @pagy = pagy
        @item_name = item_name
        @system_arguments = system_arguments
      end

      # @return [Boolean] Whether the component should render
      def render?
        @pagy.count.positive?
      end

      # @return [String] The current page range text
      def page_range_text
        t('.page_range',
          from: @pagy.from,
          to: @pagy.to,
          count: @pagy.count,
          item_name: @item_name.pluralize(@pagy.count))
      end

      private

      attr_reader :pagy, :item_name, :system_arguments

      # @return [String] Classes for the info text
      def info_text_classes
        class_names(
          'text-sm font-medium text-slate-700 dark:text-slate-300',
          'whitespace-nowrap', # Prevent text wrapping
          'flex-shrink-0' # Don't shrink in flex containers
        )
      end
    end
  end
end
