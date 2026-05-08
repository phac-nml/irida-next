# frozen_string_literal: true

module ComboboxDatepicker
  module V1
    module Calendar
      # Renders the calendar day grid.
      class GridComponent < ::Component
        def initialize(days_of_the_week:, calendar_id:)
          @days_of_the_week = days_of_the_week
          @calendar_id = calendar_id
        end
      end
    end
  end
end
