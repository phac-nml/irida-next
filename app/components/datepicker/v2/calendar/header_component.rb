# frozen_string_literal: true

module Datepicker
  module V2
    module Calendar
      # Renders the calendar header (month select and year input).
      class HeaderComponent < ::Component
        def initialize(min_year:, max_year:, months:)
          @min_year = min_year
          @max_year = max_year
          @months = months
        end
      end
    end
  end
end
