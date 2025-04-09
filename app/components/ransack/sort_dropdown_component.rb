# frozen_string_literal: true

module Ransack
  # Component for ransack sort links dropdown
  class SortDropdownComponent < Component
    attr_reader :ransack_obj, :sort_item, :sort_options, :disableable

    def initialize(ransack_obj, sort_item, sort_options, disableable: false)
      @ransack_obj = ransack_obj
      @sort_item = sort_item
      @sort_options = sort_options
      @disableable = disableable
    end
  end
end
