# frozen_string_literal: true

module Viral
  # This component is a container for the tabs.
  class SortableListsComponent < Viral::Component
    attr_reader :group, :left_id, :left_title, :left_list_items, :right_id, :right_title, :right_list_items

    def initialize(group:, # rubocop:disable Metrics/ParameterLists
                   left_id: nil,
                   left_title: nil,
                   left_list_items: [],
                   right_id: nil,
                   right_title: nil,
                   right_list_items: [])
      @group = group
      @left_id = left_id
      @left_title = left_title
      @left_list_items = left_list_items
      @right_id = right_id
      @right_title = right_title
      @right_list_items = right_list_items
    end
  end
end
