# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module MetadataTemplates
  # Component for rendering a metadata template table row
  class RowComponent < Component
    include Ransack::Helpers::FormHelper

    def initialize(metadata_template, namespace, row_actions)
      @metadata_template = metadata_template
      @namespace = namespace
      @row_actions = row_actions
      @renders_row_actions = @row_actions.any? { |_key, value| value }
      @columns = columns
    end

    def row_arguments
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(@metadata_template)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def edit_path
      if @namespace.group_namespace?
        edit_group_metadata_template_path(@namespace, @metadata_template)
      else
        edit_namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template)
      end
    end

    def individual_path
      if @namespace.group_namespace?
        group_metadata_template_path(@namespace, @metadata_template)
      else
        namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template)
      end
    end

    private

    def columns
      %i[name description created_by_email created_at updated_at]
    end
  end
end
