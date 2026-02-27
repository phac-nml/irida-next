# frozen_string_literal: true

module Datepicker
  module V1
    module Calendar
      # Renders the calendar header (month select and year input).
      class HeaderComponent < ::Component
        def initialize(min_year:, months:)
          @min_year = min_year
          @months = months
        end
      end
    end
  end
end
