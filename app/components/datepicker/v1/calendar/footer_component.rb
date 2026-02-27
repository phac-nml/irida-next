# frozen_string_literal: true

module Datepicker
  module V1
    module Calendar
      # Renders the calendar footer (today / clear buttons).
      class FooterComponent < ::Component
        def initialize(min_date:)
          @min_date = min_date
        end
      end
    end
  end
end
