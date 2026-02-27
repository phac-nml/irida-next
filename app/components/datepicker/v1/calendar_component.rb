# frozen_string_literal: true

module Datepicker
  module V1
    # Renders the datepicker calendar popup.
    class CalendarComponent < ::Component
      def initialize(calendar_arguments:, days_of_the_week:, months:, min_year:, min_date:)
        @calendar_arguments = calendar_arguments
        @days_of_the_week = days_of_the_week
        @months = months
        @min_year = min_year
        @min_date = min_date
      end
    end
  end
end
