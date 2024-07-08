# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar selected component
    class SelectedComponent < Component
      erb_template <<-ERB
        <div aria-hidden="true" class="<%= @selected_classes %>"></div>
      ERB

      def initialize(selected: nil)
        @selected = selected

        @selected_classes = class_names(
          'w-1 h-6 my-0 mr-1 rounded-lg bg-primary-600',
          {
            'rounded-lg bg-primary-600': selected,
            'bg-transparent': !selected
          }
        )
      end
    end
  end
end
