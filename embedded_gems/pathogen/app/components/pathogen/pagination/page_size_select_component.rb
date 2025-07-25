# frozen_string_literal: true

module Pathogen
  module Pagination
    # Component that renders a dropdown for selecting the number of items per page.
    # This component is used internally by the main Pagination component.
    #
    # @example Basic usage
    #   <%= render PageSizeSelectComponent.new(
    #     pagy: @pagy,
    #     page_sizes: [10, 25, 50],
    #     request: request
    #   ) %>
    #
    # @see Pathogen::Pagination::Component
    class PageSizeSelectComponent < Pathogen::Component
      # @param pagy [Pagy] The pagy instance for pagination
      # @param page_sizes [Array<Integer>] Available page sizes
      # @param request [ActionDispatch::Request] The current request object
      def initialize(pagy:, page_sizes:, request:, **system_arguments)
        super(**system_arguments)

        @pagy = pagy
        @page_sizes = page_sizes
        @request = request
        @system_arguments = system_arguments
      end

      # @return [Boolean] Whether the component should render
      def render?
        @pagy.pages > 1
      end

      private

      attr_reader :pagy, :page_sizes, :request, :system_arguments

      # @return [String] Classes for the page size select dropdown
      def select_classes
        class_names(
          'rounded-lg border border-slate-300 bg-white px-3 py-2 pr-8 text-sm text-slate-700',
          'focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500',
          'dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300',
          'dark:focus:border-primary-500 dark:focus:ring-primary-500 h-11'
        )
      end
    end
  end
end
