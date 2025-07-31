# frozen_string_literal: true

module Pathogen
  module Pagination
    # Component that provides a "Jump to page" input field for pagination.
    # This component is used internally by the main Pagination component.
    #
    # @example Basic usage
    #   <%= render JumpToComponent.new(
    #     pagy: @pagy,
    #     request: request
    #   ) %>
    #
    # @see Pathogen::Pagination::Component
    class JumpToComponent < Pathogen::Component
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

      # @return [String] Classes for the page number input (jump to page)
      def input_classes
        class_names(
          'w-20 rounded-lg border bg-white px-3 py-2 text-sm text-slate-700',
          'focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500',
          'dark:bg-slate-800 dark:text-slate-300',
          'dark:focus:border-primary-500 dark:focus:ring-primary-500',
          'transition-colors duration-200',
          # Default border colors (will be overridden by JS for validation states)
          'border-slate-300 dark:border-slate-600',
          # Invalid state styling (applied by JS)
          'invalid:border-red-500 invalid:dark:border-red-500',
          # Focus states for error conditions
          'aria-[invalid=true]:border-red-500 aria-[invalid=true]:dark:border-red-500',
          'aria-[invalid=true]:focus:border-red-600 aria-[invalid=true]:focus:ring-red-500'
        )
      end

      # @return [String] Classes for the label and info text
      def info_text_classes
        class_names('text-sm text-slate-700 dark:text-slate-300')
      end
    end
  end
end
