# frozen_string_literal: true

module Ransack
  # Component to render the hidden search field within the ransack search form
  class HiddenFieldComponent < Component
    attr_reader :ransack_obj

    def initialize(ransack_obj)
      @ransack_obj = ransack_obj
    end
  end
end
