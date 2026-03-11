# frozen_string_literal: true

module Viral
  module Dropdown
    # Item component for dropdown
    class ItemComponent < Viral::Component
      attr_reader :label, :icon, :icon_library, :url, :section_header, :params, :disableable, :prefix

      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, url: nil, params: nil, disableable: false, icon_name: nil, section_header: false,
                     prefix: nil, icon_library: nil, **system_arguments)
        @label = label
        @icon = icon_name
        @icon_library = icon_library
        @url = url
        @params = params || {}
        @disableable = disableable
        @section_header = section_header
        @prefix = prefix
        @system_arguments = system_arguments
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
