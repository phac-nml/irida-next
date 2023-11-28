# frozen_string_literal: true

module Ransack
  # Component to render the hidden search field within the ransack search form
  class SortLinksComponent < Component
    attr_reader :ransack_obj, :sort_item

    def initialize(ransack_obj, sort_item)
      @ransack_obj = ransack_obj
      @sort_item = sort_item
    end
  end
end
