# frozen_string_literal: true

module Viral
  # This component creates the sortable lists.
  class SortableListsComponent < Viral::Component
    attr_reader :title, :description

    renders_many :lists, Viral::SortableList::ListComponent

    # If creating multiple lists to utilize the same values, assign them the same group
    def initialize(title: nil, description: nil)
      @title = title
      @description = description
    end
  end
end
