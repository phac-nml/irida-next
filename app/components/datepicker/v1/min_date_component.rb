# frozen_string_literal: true

module Datepicker
  module V1
    # Renders a hidden div holding the min_date value for the datepicker Stimulus controller.
    class MinDateComponent < ::Component
      def initialize(min_date:)
        @min_date = min_date
      end
    end
  end
end
