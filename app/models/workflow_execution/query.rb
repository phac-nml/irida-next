# frozen_string_literal: true

# Model to represent workflow execution search form
# Provides advanced search capabilities for filtering workflow executions
# Supports groups, conditions, operators, basic search, and pagination
class WorkflowExecution::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  ResultTypeError = Class.new(StandardError)

  allowed_sort_columns :id, :name, :run_id, :state, :created_at, :updated_at

  attribute :name_or_id_cont, :string
  attribute :name_or_id_in, default: -> { [] }
  attribute :namespace_ids, default: -> { [] }
  attribute :groups, default: lambda {
    [WorkflowExecution::SearchGroup.new(
      conditions: [WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')]
    )]
  }

  query_for WorkflowExecution
  filter_by :namespace_id, ids: :namespace_ids
  validates_with WorkflowExecutionAdvancedSearchGroupValidator

  private

  def normalize_condition_value(condition)
    return condition.value unless condition.field == 'state'

    if %w[in not_in].include?(condition.operator)
      condition.value.map { |v| WorkflowExecution.states[v] || v }
    else
      WorkflowExecution.states[condition.value] || condition.value
    end
  end

  def ransack_params
    {
      name_or_id_cont: name_or_id_cont,
      name_or_id_in: name_or_id_in
    }.compact
  end
end
