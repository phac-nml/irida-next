# frozen_string_literal: true

module AdvancedSearch
  module V1
    # Component for rendering an advanced search value
    class ValueComponent < ::Component
      # rubocop:disable-next Metrics/ParameterLists
      def initialize(conditions_form:, group_index:, condition:, condition_index:, options: nil, datepicker: false)
        @conditions_form = conditions_form
        @group_index = group_index
        @condition = condition
        @condition_index = condition_index
        @options = options
        @datepicker = datepicker
      end

      private

      def selected_values
        Array(@condition.value).compact_blank.map(&:to_s)
      end

      def value_label
        @condition.class.human_attribute_name(:value)
      end

      def datepicker?
        @datepicker
      end

      def range_value(index)
        Array(@condition.value)[index]
      end
    end
  end
end
