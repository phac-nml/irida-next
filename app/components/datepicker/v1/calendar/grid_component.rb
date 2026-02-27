# frozen_string_literal: true

module Datepicker
  module V1
    module Calendar
      # Renders the calendar day grid.
      class GridComponent < ::Component
        def initialize(days_of_the_week:)
          @days_of_the_week = days_of_the_week
        end
      end
    end
  end
end
