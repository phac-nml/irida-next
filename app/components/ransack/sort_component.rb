# frozen_string_literal: true

module Ransack
  # Component for ransack sort in table headers
  class SortComponent < Component
    attr_reader :ransack_obj, :label, :url, :value

    def initialize(ransack_obj:, label:, url:, field:)
      @ransack_obj = ransack_obj
      @label = label
      @url = url
      @field = field
      @value = "#{field} #{@ransack_obj.sorts[0].dir == 'asc' ? 'desc' : 'asc'}"
    end

    def icon
      unless @ransack_obj&.sorts.present? && @ransack_obj.sorts[0].name == URI.encode_www_form_component(@field.to_s)
        return
      end

      @ransack_obj.sorts[0].dir == 'asc' ? 'arrow_up' : 'arrow_down'
    end
  end
end
