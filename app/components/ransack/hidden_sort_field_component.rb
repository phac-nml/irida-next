# frozen_string_literal: true

module Ransack
  # Component to render the hidden sort field within the ransack search form
  class HiddenSortFieldComponent < Component
    attr_reader :ransack_obj

    def initialize(ransack_obj)
      @ransack_obj = ransack_obj
    end

    def render?
      ransack_obj.present? && !ransack_obj.sorts.empty?
    end
  end
end
