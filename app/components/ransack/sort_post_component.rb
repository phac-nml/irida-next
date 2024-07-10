# frozen_string_literal: true

module Ransack
  # Component for ransack sort in table headers
  class SortPostComponent < Component
    attr_reader :ransack_obj, :label

    def initialize(ransack_obj:, label:, field:)
      @ransack_obj = ransack_obj
      @label = label
      @field = field
    end

    def icon
      unless @ransack_obj&.sorts.present? &&
             @ransack_obj.sorts[0].name == URI.encode_www_form_component(@field.to_s)
        return
      end

      @ransack_obj.sorts[0].dir == 'asc' ? 'arrow_up' : 'arrow_down'
    end

    def value
      q = @ransack_obj.sorts.first
      if q && q.name == URI.encode_www_form_component(@field.to_s)
        q.dir == 'asc' ? "#{@field} desc" : "#{@field} asc"
      else
        "#{@field} asc"
      end
    end
  end
end