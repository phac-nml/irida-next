# frozen_string_literal: true

module Viral
  module Dropdown
    # Item component for dropdown
    class ItemComponent < Viral::Component
      attr_reader :label, :url

      def initialize(label:, url: nil, icon_name: nil, **system_arguments)
        @label = label
        @icon_name = icon_name
        @url = url
        @system_arguments = system_arguments
      end

      def item_icon
        return if @icon_name.blank?

        icon @icon_name, class: 'size-5'
      end
    end
  end
end
