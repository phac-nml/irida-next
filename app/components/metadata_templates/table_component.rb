# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module MetadataTemplates
  # Component for rendering a table of metadata templates
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(metadata_templates, namespace, pagy, q, row_actions)
      @namespace = namespace
      @metadata_templates = metadata_templates
      @pagy = pagy
      @q = q
      @row_actions = row_actions
      @renders_row_actions = @row_actions.select { |_key, value| value }.count.positive?
      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto'),
        data: { turbo: :temporary }
      }
    end

    def row_arguments(metadata_template)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = dom_id(metadata_template)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def edit_path(metadata_template)
      if @namespace.group_namespace?
        edit_group_metadata_template_path(@namespace, metadata_template)
      else
        edit_namespace_project_metadata_template_path(@namespace.parent, @namespace.project, metadata_template)
      end
    end

    def individual_path(metadata_template)
      if @namespace.group_namespace?
        group_metadata_template_path(@namespace, metadata_template)
      else
        namespace_project_metadata_template_path(@namespace.parent, @namespace.project, metadata_template)
      end
    end

    private

    def columns
      %i[name description created_by_email created_at updated_at]
    end
  end
end
