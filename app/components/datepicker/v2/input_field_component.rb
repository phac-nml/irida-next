# frozen_string_literal: true

module Datepicker
  module V2
    # Renders the label and text input for the datepicker.
    class InputFieldComponent < ::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, input_id:, error_id:, selected_date:, input_name:, input_aria_label:, required:)
        @label = label
        @input_id = input_id
        @error_id = error_id
        @selected_date = selected_date
        @input_name = input_name
        @input_aria_label = input_aria_label
        @required = required
        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end
