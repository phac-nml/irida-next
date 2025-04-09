# frozen_string_literal: true

module Viral
  module Dropdown
    # Item component for dropdown
    class ItemComponent < Viral::Component
      attr_reader :label, :icon, :url, :section_header, :params, :disableable

      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, url: nil, params: nil, disableable: true, icon_name: nil, section_header: false,
                     **system_arguments)
        @label = label
        @icon = icon_name
        @url = url
        @params = params || {}
        @disableable = disableable
        @section_header = section_header
        @system_arguments = system_arguments
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
