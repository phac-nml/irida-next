# frozen_string_literal: true

module Viral
  # This component creates the sortable_lists.
  class SortableListsComponent < Viral::Component
    attr_reader :title, :description, :select_all_buttons

    renders_many :lists, Viral::SortableList::ListComponent

    def initialize(title: nil, description: nil, select_all_buttons: false)
      @title = title
      @description = description
      @select_all_buttons = select_all_buttons
    end
  end
end
