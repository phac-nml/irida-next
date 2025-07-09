# frozen_string_literal: true

module Viral
  module Form
    # Form text input component (numbers, email, text, etc.)
    class TestDatepickerComponent < Viral::Component
      attr_reader :id, :min_date, :selected_date, :months, :min_year

      # def initialize(container:, name:, value: nil, required: nil, pattern: nil, placeholder: nil)
      def initialize(id: 'datepicker', min_date: nil, selected_date: nil)
        @id = id
        @min_date = min_date
        @selected_date = selected_date
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
        @min_year = min_date.nil? ? '1' : min_date.split('-')[0]
      end
    end
  end
end
