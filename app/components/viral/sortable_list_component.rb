# frozen_string_literal: true

module Viral
  # This component is a container for the tabs.
  class SortableListComponent < Viral::Component
    attr_reader :group, :id, :title, :list_items

    def initialize(group: nil,
                   id: nil,
                   title: nil,
                   list_items: [],
                   **system_arguments)
      @group = group
      @id = id
      @title = title
      @list_items = list_items
      @system_arguments = system_arguments
      @system_arguments[:list_classes] = class_names(system_arguments[:list_classes])
      @system_arguments[:container_classes] = class_names(system_arguments[:container_classes])
    end
  end
end
