# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar section component to group items
    class SectionComponent < Component
      attr_reader :title

      renders_many :items, ItemComponent
      renders_many :dropdowns, Viral::DropdownComponent

      def initialize(title: nil)
        @title = title
      end
    end
  end
end
