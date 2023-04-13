# frozen_string_literal: true

module Viral
  module Dropdown
    # Item component for dropdown
    class ItemComponent < Viral::Component
      def initialize(label:, url: nil, icon_name: nil)
        @label = label
        @icon = icon_name
        @url = url
      end
    end
  end
end
