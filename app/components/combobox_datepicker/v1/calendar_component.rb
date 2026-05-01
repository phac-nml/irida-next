# frozen_string_literal: true

module ComboboxDatepicker
  module V1
    # Renders the datepicker calendar popup.
    class CalendarComponent < ::Component
      def initialize(calendar_arguments:, days_of_the_week:, months:, min_date:)
        @calendar_arguments = calendar_arguments
        @days_of_the_week = days_of_the_week
        @months = months
        @min_date = min_date
        @min_year = calculate_min_year
      end

      private

      def calculate_min_year
        @min_date.nil? ? '1' : @min_date.to_s.split('-')[0]
      end
    end
  end
end
