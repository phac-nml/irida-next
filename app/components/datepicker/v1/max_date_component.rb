# frozen_string_literal: true

module Datepicker
  module V1
    # Renders a hidden div holding the max_date value for the datepicker Stimulus controller.
    class MaxDateComponent < ::Component
      def initialize(max_date:)
        @max_date = max_date
      end
    end
  end
end
