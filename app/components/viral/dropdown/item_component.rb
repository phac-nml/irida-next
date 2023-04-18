# frozen_string_literal: true

module Viral
  module Dropdown
    # Item component for dropdown
    class ItemComponent < Viral::Component
      attr_reader :label, :icon, :url

      def initialize(label:, url: nil, icon_name: nil, **system_arguments)
        @label = label
        @icon = icon_name
        @url = url
        @system_arguments = system_arguments
      end
    end
  end
end
