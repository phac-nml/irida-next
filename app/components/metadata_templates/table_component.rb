# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module MetadataTemplates
  # Component for rendering a table of metadata templates
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName, Metrics/ParameterLists
    def initialize(namespace, metadata_templates, pagy, q, current_user, empty = {}, abilities = {})
      @namespace = namespace
      @metadata_templates = metadata_templates
      @pagy = pagy
      @q = q
      @current_user = current_user
      @abilities = abilities
      @columns = columns
      @empty = empty
    end
    # rubocop:enable Naming/MethodParameterName, Metrics/ParameterLists

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto'),
        data: { turbo: :temporary }
      }
    end

    def row_arguments(member)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = dom_id(member)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def abilities_metadata_templates_path(metadata_template)
      if @namespace.group_namespace?
        group_metadata_template_path(@namespace, metadata_template)
      else
        namespace_project_metadata_template_path(@namespace.parent, @namespace.project, metadata_template)
      end
    end

    private

    def columns
      %i[name description created_by created_at updated_at]
    end
  end
end
