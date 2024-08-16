# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Groups
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName,Metrics/ParameterLists
    def initialize(
      namespace_group_links,
      namespace,
      access_levels,
      q,
      abilities: {},
      **system_arguments
    )
      @namespace_group_links = namespace_group_links
      @namespace = namespace
      @access_levels = access_levels
      @q = q
      @abilities = abilities
      @system_arguments = system_arguments

      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName,Metrics/ParameterLists

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container relative overflow-x-auto'),
        data: { turbo: :temporary }
      }
    end

    def row_arguments(namespace_group_link)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = dom_id(namespace_group_link)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def select_group_link_path(namespace_group_link)
      if @namespace.type == 'Group'
        group_group_link_path(@namespace, namespace_group_link)
      else
        namespace_project_group_link_path(@namespace.parent, @namespace.project, namespace_group_link)
      end
    end

    private

    def columns
      %i[group_name namespace_name updated_at group_access_level expires_at]
    end
  end
end
