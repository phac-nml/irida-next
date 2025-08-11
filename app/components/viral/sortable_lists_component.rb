# frozen_string_literal: true

module Viral
  # This component creates the sortable_lists.
  class SortableListsComponent < Viral::Component
    attr_reader :title, :description, :templates, :template_label,
                :required

    renders_many :lists, lambda { |id:, group:, title:, **system_arguments|
      Viral::SortableList::ListComponent.new(id:, group:, title:, required: @required, **system_arguments)
    }

    def initialize(title: nil, description: nil, templates: [], template_label: nil, required: false)
      @title = title
      @description = description
      @templates = templates
      @template_label = template_label
      @required = required
    end
  end
end
