# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar selected component
    class SelectedComponent < Component
      attr_reader :selected

      def initialize(selected: nil)
        @selected = selected
      end
    end
  end
end
