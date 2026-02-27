# frozen_string_literal: true

module Datepicker
  module V1
    # Renders the label and text input for the datepicker.
    class InputFieldComponent < ::Component
      def initialize(label:, input_id:, selected_date:, input_name:, input_aria_label:)
        @label = label
        @input_id = input_id
        @selected_date = selected_date
        @input_name = input_name
        @input_aria_label = input_aria_label
      end
    end
  end
end
