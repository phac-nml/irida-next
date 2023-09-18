# frozen_string_literal: true

module Viral
  module Form
    class SelectComponent < Viral::Component
      attr_reader :label, :name, :multiple, :options, :default

      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, name:, options: [], multiple: false, default: nil, **_options)
        @label = label
        @name = name
        @multiple = multiple
        @default = default
        @options = options
      end
    end
  end
end
