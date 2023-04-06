# frozen_string_literal: true

module Layout
  module Sidebar
    class SectionComponent < Component
      renders_many :items, ItemComponent

      def initialize(title: nil)
        @title = title
      end
    end
  end
end
