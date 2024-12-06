# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar label component
    class LabelComponent < Component
      attr_reader :label, :icon, :url

      def initialize(label:, icon:, url:)
        @label = label
        @icon = icon
        @url = url
      end
    end
  end
end
