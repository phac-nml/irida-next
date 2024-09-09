# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy component for the limit
    class LimitComponent < Viral::Component
      def initialize(pagy, item:, **system_arguments)
        @pagy = pagy
        @item = item
        @system_arguments = system_arguments
      end

      def system_arguments
        { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
          args[:classes] = class_names('inline-flex items-center mt-4 space-x-2 text-slate-500 dark:text-slate-400')
        end
      end
    end
  end
end
