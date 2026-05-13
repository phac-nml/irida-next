# frozen_string_literal: true

module ComboboxDatepicker
  module V1
    module Calendar
      # Renders the calendar header (month select and year input).
      class HeaderComponent < ::Component
        def initialize(min_year:, months:, calendar_id_header:)
          @min_year = min_year
          @months = months
          @calendar_id_header = calendar_id_header
        end
      end
    end
  end
end
