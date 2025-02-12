# frozen_string_literal: true

module Viral
  # This component creates the sortable_lists.
  class SortableListsComponent < Viral::Component
    attr_reader :title, :description, :templates, :template_label

    renders_many :lists, Viral::SortableList::ListComponent

    def initialize(title: nil, description: nil, templates: [], template_label: nil)
      @title = title
      @description = description
      @templates = templates
      @template_label = template_label
    end
  end
end
