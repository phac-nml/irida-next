# frozen_string_literal: true

module Ransack
  # Component for ransack sort in table headers
  class SortComponent < Component
    attr_reader :ransack_obj, :label, :field, :url

    def initialize(ransack_obj:, label:, url:, field:)
      @ransack_obj = ransack_obj
      @label = label
      @url = url
      @field = field
    end

    def icon
      return unless @ransack_obj.sorts[0].attr_name == @field.to_s

      @ransack_obj.sorts[0].dir == 'asc' ? 'arrow_up' : 'arrow_down'
    end
  end
end
