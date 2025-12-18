# frozen_string_literal: true

# Model to represent workflow execution search form
# Provides advanced search capabilities for filtering workflow executions
# Supports groups, conditions, operators, basic search, and pagination
class WorkflowExecution::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  ResultTypeError = Class.new(StandardError)

  ALLOWED_SORT_COLUMNS = %w[id name run_id state created_at updated_at].freeze

  attribute :name_or_id_cont, :string
  attribute :name_or_id_in, default: -> { [] }
  attribute :namespace_ids, default: -> { [] }
  attribute :groups, default: lambda {
    [WorkflowExecution::SearchGroup.new(
      conditions: [WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')]
    )]
  }

  validates :namespace_ids, length: { minimum: 1 }
  validates_with WorkflowExecutionAdvancedSearchGroupValidator

  private

  def model_class
    WorkflowExecution
  end

  def filter_column
    :namespace_id
  end

  def filter_ids
    namespace_ids
  end

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
