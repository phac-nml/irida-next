# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module WorkflowExecutions
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName,Metrics/ParameterLists
    def initialize(
      workflow_executions,
      pagy,
      q,
      namespace: nil,
      row_actions: false,
      search_params: nil,
      abilities: {},
      empty: {},
      **system_arguments
    )
      @workflow_executions = workflow_executions
      @pagy = pagy
      @q = q
      @namespace = namespace
      @abilities = abilities
      @search_params = search_params
      @row_actions = row_actions
      @empty = empty
      @renders_row_actions = @row_actions.select { |_key, value| value }.count.positive?
      @system_arguments = system_arguments

      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName,Metrics/ParameterLists

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = 'workflow-executions-table'
        args[:classes] = class_names(args[:classes], 'relative', 'overflow-x-auto')
        if @abilities[:select_workflow_executions]
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
        classes: class_names('table-container')
      }
    end

    def row_arguments(sample)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = sample.id
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def cancel_path(workflow_execution)
      if @namespace
        cancel_namespace_project_workflow_execution_path(
          @namespace.parent,
          @namespace.project,
          workflow_execution
        )
      else
        cancel_workflow_execution_path(workflow_execution)
      end
    end

    def individual_path(workflow_execution)
      if @namespace && @namespace.type == 'Project'
        namespace_project_workflow_execution_path(
          @namespace.parent,
          @namespace.project,
          workflow_execution
        )
      elsif @namespace && @namespace.type == 'Group'
        group_workflow_execution_path(@namespace, workflow_execution)
      else
        workflow_execution_path(workflow_execution)
      end
    end

    private

    def columns
      %i[id name state run_id workflow_name workflow_version created_at updated_at]
    end
  end
end
