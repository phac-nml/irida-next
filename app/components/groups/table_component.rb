# frozen_string_literal: true

module Groups
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    def initialize(
      namespace_group_links,
      namespace,
      access_levels,
      q,
      abilities: {},
      has_groups: true,
      search_params: {},
      **system_arguments
    )
      @namespace_group_links = namespace_group_links
      @namespace = namespace
      @access_levels = access_levels
      @q = q
      @abilities = abilities
      @has_groups = has_groups
      @search_params = search_params
      # @row_actions = row_actions
      # @renders_row_actions = @row_actions.select { |_key, value| value }.count.positive?
      @system_arguments = system_arguments

      @columns = columns
    end

    # def system_arguments
    #   { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
    #     args[:id] = 'samples-table'
    #     args[:classes] = class_names(args[:classes], 'relative', 'overflow-x-auto')
    #     if @abilities[:select_samples]
    #       args[:data] ||= {}
    #       args[:data][:controller] = 'selection'
    #       args[:data][:'selection-total-value'] = @pagy.count
    #       args[:data][:'selection-action-link-outlet'] = '.action-link'
    #     end
    #   end
    # end

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

    # def select_samples_url(**)
    #   if @namespace.type == 'Group'
    #     select_group_samples_url(@namespace, **)
    #   else
    #     select_namespace_project_samples_url(@namespace.parent, @namespace.project, **)
    #   end
    # end

    private

    def columns
      %i[group_name namespace_name updated_at group_access_level expires_at]
    end
  end
end
