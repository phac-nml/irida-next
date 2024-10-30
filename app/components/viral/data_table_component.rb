# frozen_string_literal: true

module Viral
  # This component creates the individual lists for the sortable_lists_component.
  class DataTableComponent < Viral::Component # rubocop:disable Metrics/ClassLength
    renders_many :columns, Viral::DataTable::ColumnComponent

    # If creating multiple lists to utilize the same list values, assign them the same group
    # rubocop:disable Metrics/ParameterLists
    def initialize(
      type: '',
      data: [],
      has_data: false,
      pagy: nil,
      q: nil, # rubocop:disable Naming/MethodParameterName
      abilities: {},
      row_actions: {},
      empty: {},
      **system_arguments
    )
      @type = type
      @data = data
      @has_data = has_data
      @pagy = pagy
      @q = q
      @abilities = abilities
      @row_actions = row_actions
      @renders_row_actions = @row_actions.select { |_key, value| value }.count.positive?
      @empty = empty
      @system_arguments = system_arguments
    end

    # rubocop:enable Metrics/ParameterLists

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = "#{@type}_table"
        args[:classes] = class_names(args[:classes], 'overflow-auto scrollbar')
        if @abilities[:select]
          args[:data] ||= {}
          args[:data][:controller] = 'selection'
          args[:data][:'selection-total-value'] = @pagy.count
          args[:data][:'selection-action-link-outlet'] = '.action-link'
        end
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container flex flex-col shrink min-h-0 data-turbo-temporary'),
        scope: 'col'
      }
    end

    def row_arguments(data)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = data.id
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def verify_action_render(action, data)
      return data.cancellable? if action == :cancel

      return unless action == :destroy

      data.deletable?
    end

    def action_arguments(action, data)
      default_args = {
        tag: 'a',
        classes: class_names('font-medium', 'text-blue-600', 'underline', 'dark:text-blue-500', 'hover:no-underline',
                             'cursor-pointer')
      }
      additional_args = if @type == 'workflow_executions'
                          workflow_execution_actions(action, data)
                        elsif @type == 'samples'
                          sample_actions(action, data)
                        end
      default_args.merge(additional_args)
    end

    def workflow_execution_actions(action, data) # rubocop:disable Metrics/AbcSize
      args = {}
      args[:data] ||= {}
      if action == :cancel
        args[:data][:turbo_stream] = true
        args[:data][:turbo_method] = :put
        args[:data][:turbo_confirm] = t(:'workflow_executions.index.actions.cancel_confirm')
        args[:href] = workflow_execution_cancel_path(data)
      elsif action == :destroy
        args[:data][:turbo_stream] = true
        args[:data][:turbo_method] = :delete
        args[:data][:turbo_confirm] = t(:'workflow_executions.index.actions.delete_confirm')
        args[:href] = individual_path(data)
      end
      args
    end

    def sample_actions(action, data)
      args = {}
      args[:data] ||= {}

      if action == :edit
        args[:href] = edit_project_sample_path(data.project, data)
        args[:data][:turbo] = false
      elsif action == :destroy
        args[:href] = new_namespace_project_samples_deletion_path(
          sample_id: data.id,
          deletion_type: 'single'
        )
        args[:data][:turbo_stream] = true
      end
      args
    end

    def individual_path(data)
      return unless data.is_a?(WorkflowExecution)

      if system_arguments[:namespace]
        namespace_project_workflow_execution_path(
          system_arguments[:namespace].parent,
          system_arguments[:namespace].project,
          data
        )
      else
        workflow_execution_path(data)
      end
    end

    def workflow_execution_cancel_path(workflow_execution)
      if system_arguments[:namespace]
        cancel_namespace_project_workflow_execution_path(
          system_arguments[:namespace].parent,
          system_arguments[:namespace].project,
          workflow_execution
        )
      else
        cancel_workflow_execution_path(workflow_execution)
      end
    end
  end
end
