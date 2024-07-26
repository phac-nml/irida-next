# frozen_string_literal: true

module Viral
  # This component creates a sortable list.
  class SortableListComponent < Viral::Component
    attr_reader :group, :title, :list_items

    # If creating multiple lists to utilize the same values, assign them the same group
    def initialize(group: nil,
                   title: nil,
                   list_items: [],
                   **system_arguments)
      @group = group
      @title = title
      @list_items = list_items
      @system_arguments = system_arguments
      @system_arguments[:list_classes] = class_names(system_arguments[:list_classes])
      @system_arguments[:container_classes] = class_names(system_arguments[:container_classes])
    end
  end
end
