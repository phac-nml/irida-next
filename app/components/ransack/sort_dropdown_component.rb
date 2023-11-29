# frozen_string_literal: true

module Ransack
  # Component for ransack sort links dropdown
  class SortDropdownComponent < Component
    attr_reader :ransack_obj, :sort_item, :sort_options

    def initialize(ransack_obj, sort_item, sort_options)
      @ransack_obj = ransack_obj
      @sort_item = sort_item
      @sort_options = sort_options
    end
  end
end
