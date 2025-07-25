# frozen_string_literal: true

module Pathogen
  module Pagination
    # Component that renders pagination links including previous/next buttons and page numbers.
    # This component is used internally by the main Pagination component.
    #
    # @example Basic usage
    #   <%= render PageLinksComponent.new(pagy: @pagy, request: request) %>
    #
    # @see Pathogen::Pagination::Component
    class PageLinksComponent < Pathogen::Component
      # @param pagy [Pagy] The pagy instance for pagination
      # @param request [ActionDispatch::Request] The current request object
      def initialize(pagy:, request:, **system_arguments)
        super(**system_arguments)

        @pagy = pagy
        @request = request
        @system_arguments = system_arguments
      end

      # @return [Boolean] Whether the component should render
      def render?
        @pagy.pages > 1
      end

      private

      attr_reader :pagy, :request, :system_arguments

      # Generate the URL for a specific page
      # @param page [Integer] The page number to generate URL for
      # @return [String] The generated URL
      def page_url(page)
        url_for(params: request.query_parameters.merge(page: page, limit: pagy.vars[:items]))
      end

      # Delegate to class methods for consistency
      def pagination_link_classes(is_first:, is_last:, prev_is_gap:, next_is_selected:)
        class_names(
          'flex items-center justify-center text-slate-700 bg-white border border-slate-300',
          'font-medium text-sm px-4 h-11 hover:bg-slate-100 hover:text-slate-900',
          'dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700',
          'dark:hover:bg-slate-700 dark:hover:text-slate-100',
          'focus:z-50 focus:relative focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2',
          'dark:focus:ring-primary-400 dark:focus:ring-offset-slate-800',
          { 'rounded-s-lg' => is_first, 'rounded-e-lg' => is_last, 'border-l-0' => !is_first || prev_is_gap,
            'border-r-0' => next_is_selected }
        )
      end

      def pagination_selected_classes(is_first:, is_last:)
        class_names(
          'flex items-center justify-center px-4 h-11 ms-0 leading-tight border border-primary-600',
          'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-200',
          'font-bold text-sm cursor-default',
          'focus:z-50 focus:relative focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2',
          'dark:focus:ring-primary-400 dark:focus:ring-offset-slate-800',
          { 'rounded-s-lg' => is_first, 'rounded-e-lg' => is_last }
        )
      end

      def pagination_gap_classes(is_first:, is_last:, show_left:, show_right:)
        class_names(
          'flex items-center justify-center px-4 h-11 ms-0 leading-tight border-t border-b',
          'border-slate-300 dark:border-slate-700 text-slate-600 bg-slate-100',
          'dark:bg-slate-800 dark:text-slate-400 cursor-default',
          { 'border-l border-slate-300 dark:border-slate-700' => !is_first && show_left,
            'border-r border-slate-300 dark:border-slate-700' => show_right,
            'rounded-s-lg' => is_first,
            'rounded-e-lg' => is_last }
        )
      end
    end
  end
end
