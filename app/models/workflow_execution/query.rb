# frozen_string_literal: true

# Model to represent workflow execution search form
# Provides advanced search capabilities for filtering workflow executions
# Supports groups, conditions, operators, basic search, and pagination
class WorkflowExecution::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedSearchable
  include AdvancedSearchConditions

  ResultTypeError = Class.new(StandardError)

  attribute :column, :string
  attribute :direction, :string
  attribute :name_or_id_cont, :string
  attribute :name_or_id_in, default: -> { [] }
  attribute :namespace_ids, default: -> { [] }
  attribute :groups, default: lambda {
    [WorkflowExecution::SearchGroup.new(
      conditions: [WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')]
    )]
  }
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :namespace_ids, length: { minimum: 1 }
  validates_with WorkflowExecutionAdvancedSearchGroupValidator

  def initialize(...)
    super
    self.sort = sort
    self.advanced_query = advanced_query?
    self.groups = groups
  end

  def results(**results_arguments)
    if results_arguments[:limit] || results_arguments[:page]
      pagy_results(results_arguments[:limit], results_arguments[:page])
    else
      non_pagy_results
    end
  end

  private

  def pagy_results(limit, page)
    pagy(ransack_results, limit:, page:)
  end

  def non_pagy_results
    ransack_results
  end

  def ransack_results
    return WorkflowExecution.none unless valid?

    scope = if advanced_query
              sort_workflow_executions(advanced_query_scope)
            else
              sort_workflow_executions
            end

    scope.ransack(ransack_params).result
  end

  def advanced_query_scope
    WorkflowExecution.where(namespace_id: namespace_ids).and(advanced_query_groups)
  end

  def advanced_query_groups
    adv_query_scope = nil
    groups.each do |group|
      group_scope = WorkflowExecution
      group.conditions.map do |condition|
        group_scope = add_condition(group_scope, condition)
      end
      adv_query_scope = if adv_query_scope.nil?
                          group_scope
                        else
                          adv_query_scope.or(group_scope)
                        end
    end
    adv_query_scope
  end

  def add_condition(scope, condition) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    node = build_arel_node(condition, WorkflowExecution)
    value = convert_state_enum_value(condition)
    metadata_field = condition.field.starts_with? 'metadata.'

    case condition.operator
    when '='
      handle_equals_operator(scope, node, value, metadata_field:, field_name: condition.field)
    when 'in'
      handle_in_operator(scope, node, value, metadata_field:, field_name: condition.field)
    when '!='
      handle_not_equals_operator(scope, node, value, metadata_field:, field_name: condition.field)
    when 'not_in'
      handle_not_in_operator(scope, node, value, metadata_field:, field_name: condition.field)
    when '<='
      handle_less_than_or_equal(scope, node, value, condition.field, metadata_field)
    when '>='
      handle_greater_than_or_equal(scope, node, value, condition.field, metadata_field)
    when 'contains'
      condition_contains(scope, node, value)
    when 'not_contains'
      condition_not_contains(scope, node, value)
    when 'exists'
      condition_exists(scope, node)
    when 'not_exists'
      condition_not_exists(scope, node)
    end
  end

  def handle_less_than_or_equal(scope, node, value, field, metadata_field)
    metadata_key = field.gsub(/^metadata./, '')
    condition_less_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
  end

  def handle_greater_than_or_equal(scope, node, value, field, metadata_field)
    metadata_key = field.gsub(/^metadata./, '')
    condition_greater_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
  end

  def convert_state_enum_value(condition)
    return condition.value unless condition.field == 'state'

    if %w[in not_in].include?(condition.operator)
      condition.value.map { |v| WorkflowExecution.states[v] || v }
    else
      WorkflowExecution.states[condition.value] || condition.value
    end
  end

  def handle_equals_operator(scope, node, value, metadata_field:, field_name:)
    condition_equals(scope, node, value, metadata_field:, field_name:)
  end

  def handle_in_operator(scope, node, value, metadata_field:, field_name:)
    condition_in(scope, node, value, metadata_field:, field_name:)
  end

  def handle_not_equals_operator(scope, node, value, metadata_field:, field_name:)
    condition_not_equals(scope, node, value, metadata_field:, field_name:)
  end

  def handle_not_in_operator(scope, node, value, metadata_field:, field_name:)
    condition_not_in(scope, node, value, metadata_field:, field_name:)
  end

  def ransack_params
    {
      name_or_id_cont: name_or_id_cont,
      name_or_id_in: name_or_id_in
    }.compact
  end

  def sort_workflow_executions(scope = WorkflowExecution.where(namespace_id: namespace_ids))
    if column.starts_with? 'metadata.'
      field = column.gsub('metadata.', '')
      scope.order(WorkflowExecution.metadata_sort(field, direction))
    else
      scope.order("#{column} #{direction}")
    end
  end
end
