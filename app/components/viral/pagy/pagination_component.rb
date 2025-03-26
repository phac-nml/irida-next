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
        "#{default_link_classes} text-slate-500 bg-white hover:bg-slate-100 hover:text-slate-700 dark:bg-slate-800  dark:text-slate-400 dark:hover:bg-slate-700 dark:hover:text-white" # rubocop:disable Layout/LineLength
      end

      def disabled_link_classes
        "#{default_link_classes} cursor-not-allowed opacity-50 text-slate-600 bg-slate-50 dark:bg-slate-700 dark:text-slate-400"
      end

      def current_link_classes
        "#{default_link_classes} cursor-not-allowed text-primary-800 bg-primary-50 hover:bg-primary-100 hover:text-primary-700 dark:bg-slate-700 dark:text-white" # rubocop:disable Layout/LineLength
      end

      def invisible_link_classes
        '@max-md:invisible @max-md:w-0 @max-md:p-0 @max-md:border-none'
      end

      private

      def default_link_classes
        'flex items-center justify-center px-4 h-10 ms-0 leading-tight border border-slate-300 dark:border-slate-700'
      end
    end
  end
end
