# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy pagination component
    class PaginationComponent < Viral::Component
      def initialize(pagy, data_string: 'data-turbo-action="replace"')
        @pagy = pagy
        @data_string = data_string
      end

      def render?
        @pagy.next || @pagy.prev
      end

      def active_link_classes
        "#{default_link_classes} text-slate-700 bg-slate-200 hover:bg-slate-300 hover:text-slate-900 dark:bg-slate-700 dark:text-slate-200 dark:hover:bg-slate-600 dark:hover:text-white"
      end

      def disabled_link_classes
        "#{default_link_classes} cursor-not-allowed text-slate-600 bg-slate-300 dark:bg-slate-800 dark:text-slate-500 dark:border-slate-600"
      end

      def current_link_classes
        "#{default_link_classes} text-white bg-primary-600 dark:bg-primary-700 dark:text-white"
      end

      def invisible_link_classes
        '@max-md:invisible @max-md:w-0 @max-md:p-0 @max-md:border-none'
      end

      private

      def default_link_classes
        'flex items-center justify-center px-4 h-10 ms-0 leading-tight border border-slate-300 dark:border-slate-600'
      end
    end
  end
end
