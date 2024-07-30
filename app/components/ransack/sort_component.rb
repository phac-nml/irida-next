# frozen_string_literal: true

module Ransack
  # Component for ransack sort in table headers
  class SortComponent < Component
    attr_reader :ransack_obj, :label, :field, :url

    def initialize(ransack_obj:, label:, url:, field:, **system_arguments)
      @ransack_obj = ransack_obj
      @label = label
      @url = url
      @field = field
      @system_arguments = system_arguments
    end

    def system_arguments
      if @system_arguments.empty?
        { data: {
          turbo_stream: 'true'
        } }
      else
        @ystem_arguments
      end
    end

    def icon
      unless @ransack_obj&.sorts.present? && @ransack_obj.sorts[0].name == URI.encode_www_form_component(@field.to_s)
        return
      end

      @ransack_obj.sorts[0].dir == 'asc' ? 'arrow_up' : 'arrow_down'
    end
  end
end
