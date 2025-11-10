# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module WorkflowExecutions
  # Component for rendering a table of Samples
  class TableComponent < Component # rubocop:disable Metrics/ClassLength
    include Ransack::Helpers::FormHelper

    # 🧊 Fields within the 'metadata' JSONB column that require prefixing for sorting.
    METADATA_FIELDS = %i[workflow_name workflow_version].freeze

    # rubocop:disable Naming/MethodParameterName,Metrics/ParameterLists
    def initialize(
      workflow_executions,
      pagy,
      q,
      has_workflow_executions,
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
      @has_workflow_executions = has_workflow_executions
      @namespace = namespace
      @abilities = abilities
      @search_params = search_params
      @row_actions = row_actions
      @empty = empty
      @renders_row_actions = @row_actions.any? { |_key, value| value }
      @system_arguments = system_arguments

      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName,Metrics/ParameterLists

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = 'workflow-executions-table'
        args[:classes] = class_names(args[:classes], 'relative', 'overflow-x-auto')
        add_selection_data_attributes(args) if @abilities[:select_workflow_executions]
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container')
      }
    end

    def row_arguments(workflow_execution)
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white dark:bg-slate-800',
                      'border-b border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(workflow_execution)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    # 💡 Determines the actual database column name for sorting purposes.
    #    Certain display columns (like workflow name/version) are stored
    #    within a JSONB 'metadata' column and need prefixing for Ransack.
    #
    # @param column [Symbol] The symbolic name of the column used in the view.
    # @return [String] The corresponding database column name suitable for Ransack sorting.
    def sort_column_name(column)
      # 🛡️ Return the column name directly if it's not a special metadata field.
      return column.to_s unless METADATA_FIELDS.include?(column)

      # special handling for workflow_name as we are actually sorting on pipeline_id
      return 'metadata_pipeline_id' if column == :workflow_name

      # 🔧 Prefix metadata fields stored in the JSONB column.
      "metadata_#{column}"
    end

    private

    def add_selection_data_attributes(args)
      args[:data] ||= {}
      args[:data][:controller] = 'selection'
      args[:data][:'selection-total-value'] = @pagy.count
      args[:data][:'selection-action-button-outlet'] = '.action-button'
      args[:data][:'selection-count-message-one-value'] =
        I18n.t('components.workflow_executions.table_component.counts.one')
      args[:data][:'selection-count-message-other-value'] =
        I18n.t('components.workflow_executions.table_component.counts.other')
    end

    def columns
      %i[id name state run_id workflow_name workflow_version created_at updated_at]
    end

    def individual_path(workflow_execution)
      if @namespace&.project_namespace?
        namespace_project_workflow_execution_path(
          @namespace.parent,
          @namespace.project,
          workflow_execution
        )
      elsif @namespace&.group_namespace?
        group_workflow_execution_path(@namespace, workflow_execution)
      else
        workflow_execution_path(workflow_execution)
      end
    end

    def cancel_path(workflow_execution)
      if @namespace&.project_namespace?
        cancel_namespace_project_workflow_execution_path(
          @namespace.parent,
          @namespace.project,
          workflow_execution
        )
      elsif @namespace&.group_namespace?
        cancel_group_workflow_execution_path(@namespace, workflow_execution)
      else
        cancel_workflow_execution_path(workflow_execution)
      end
    end

    def destroy_confirmation_path(workflow_execution)
      if @namespace&.project_namespace?
        destroy_confirmation_namespace_project_workflow_execution_path(@namespace.parent,
                                                                       @namespace.project,
                                                                       workflow_execution)
      elsif @namespace&.group_namespace?
        # Groups don't have destroy_confirmation route, use destroy directly
        group_workflow_execution_path(@namespace, workflow_execution)
      else
        destroy_confirmation_workflow_execution_path(workflow_execution)
      end
    end
  end
end
