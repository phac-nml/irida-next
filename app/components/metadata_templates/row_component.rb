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

    # Renders the body of a metadata template's table cell for the given column.
    def metadata_template_cell_content(column)
      case column
      when :name
        content_tag(:span, @metadata_template.name, class: 'font-semibold text-slate-900 dark:text-slate-100')
      when :description
        @metadata_template.description
      when :created_by_email
        @metadata_template.created_by.email
      when :created_at
        helpers.local_date(@metadata_template.created_at, :long)
      when :updated_at
        helpers.local_time_ago(@metadata_template.updated_at)
      end
    end

    def edit_path
      if @namespace.group_namespace?
        helpers.edit_group_metadata_template_path(@namespace, @metadata_template)
      else
        helpers.edit_namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template)
      end
    end

    def individual_path
      if @namespace.group_namespace?
        helpers.group_metadata_template_path(@namespace, @metadata_template)
      else
        helpers.namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template)
      end
    end

    private

    def columns
      %i[name description created_by_email created_at updated_at]
    end
  end
end
