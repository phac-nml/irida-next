# frozen_string_literal: true

module Viral
  # This component creates the sortable_lists.
  class SortableListsComponent < Viral::Component
    renders_many :lists, Viral::SortableList::ListComponent

    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end
  end
end
