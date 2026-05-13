# frozen_string_literal: true

module ComboboxDatepicker
  module V1
    # Renders the datepicker calendar popup.
    class CalendarComponent < ::Component
      def initialize(calendar_arguments:, days_of_the_week:, months:, min_date:, max_date:)
        @calendar_arguments = calendar_arguments
        @days_of_the_week = days_of_the_week
        @months = months
        @min_date = min_date
        @max_date = max_date
        @min_year = calculate_min_year
        @max_year = calculate_max_year
      end

      def calculate_min_year
        @min_date.nil? ? '1' : isolate_year(@min_date)
      end

      def calculate_max_year
        @max_date.nil? ? '9999' : isolate_year(@max_date)
      end

      private

      def isolate_year(date)
        date.to_s.split('-')[0]
      end
    end
  end
end
