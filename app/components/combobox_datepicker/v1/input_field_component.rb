# frozen_string_literal: true

module ComboboxDatepicker
  module V1
    # Renders the label and text input for the datepicker.
    class InputFieldComponent < ::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, input_id:, error_id:, selected_date:, input_name:, input_aria_label:, required:,
                     errored:, calendar_id:)
        @label = label
        @input_id = input_id
        @error_id = error_id
        @selected_date = selected_date
        @input_name = input_name
        @input_aria_label = input_aria_label
        @required = required
        @errored = errored # errored boolean from backend validation, allowing us to set aria-describedby
        @calendar_id = calendar_id
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
