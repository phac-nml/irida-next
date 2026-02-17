# frozen_string_literal: true

# Model to represent workflow execution search form
# Provides advanced search capabilities for filtering workflow executions
# Supports groups, conditions, operators, basic search, and pagination
class WorkflowExecution::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  class ResultTypeError < StandardError
  end

  allowed_sort_columns :id, :name, :run_id, :state, :created_at, :updated_at

  self.enum_metadata_fields = WorkflowExecution::FieldConfiguration::ENUM_METADATA_FIELDS

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
  validates_with WorkflowExecution::AdvancedSearchGroupValidator

  private

  def normalize_condition_value(condition)
    return normalize_state_value(condition) if condition.field == 'state'

    condition.value
  end

  def normalize_state_value(condition)
    if %w[in not_in].include?(condition.operator)
      Array(condition.value).map { |v| WorkflowExecution.states[v] || v }
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
