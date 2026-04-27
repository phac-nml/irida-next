# frozen_string_literal: true

module Datepicker
  module V2
    # Renders the datepicker calendar popup.
    class CalendarComponent < ::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(calendar_arguments:, days_of_the_week:, months:, min_year:, min_date:, max_date:)
        @calendar_arguments = calendar_arguments
        @days_of_the_week = days_of_the_week
        @months = months
        @min_year = min_year
        @min_date = min_date
        @max_date = max_date
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
