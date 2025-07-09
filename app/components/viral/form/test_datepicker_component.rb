# frozen_string_literal: true

module Viral
  module Form
    # Form text input component (numbers, email, text, etc.)
    class TestDatepickerComponent < Viral::Component
      attr_reader :input_id, :input_name, :id, :min_date, :selected_date, :months, :min_year, :autosubmit

      def initialize(input_id: nil, input_name: '', id: 'datepicker', min_date: nil, selected_date: nil,
                     autosubmit: false)
        @input_id = input_id
        @input_name = input_name
        @id = id
        @min_date = min_date
        @selected_date = selected_date
        @autosubmit = autosubmit
        @months = %w[
          January
          February
          March
          April
          May
          June
          July
          August
          September
          October
          November
          December
        ]

        @min_year = min_date.nil? ? '1' : min_date.to_s.split('-')[0]
      end
    end
  end
end
