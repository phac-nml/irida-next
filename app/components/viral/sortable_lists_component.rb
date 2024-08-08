# frozen_string_literal: true

module Viral
  # This component creates the sortable_lists.
  class SortableListsComponent < Viral::Component
    attr_reader :title, :description

    renders_many :lists, Viral::SortableList::ListComponent

    def initialize(title: nil, description: nil)
      @title = title
      @description = description
    end
  end
end
