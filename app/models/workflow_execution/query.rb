# frozen_string_literal: true

# Model to represent workflow execution search form
# Provides advanced search capabilities for filtering workflow executions
# Supports groups, conditions, operators, basic search, and pagination
class WorkflowExecution::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedSearchable

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

  def add_condition(scope, condition) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    metadata_field = condition.field.starts_with? 'metadata.'
    metadata_key = (condition.field.gsub(/^metadata./, '') if metadata_field)
    node = if metadata_field
             Arel::Nodes::InfixOperation.new('->>', WorkflowExecution.arel_table[:metadata],
                                             Arel::Nodes::Quoted.new(metadata_key))
           else
             WorkflowExecution.arel_table[condition.field]
           end

    # Convert state enum string values to integers before building predicates
    converted_value = condition.value
    if condition.field == 'state'
      converted_value = if %w[in not_in].include?(condition.operator)
                          condition.value.map { |v| WorkflowExecution.states[v] || v }
                        else
                          WorkflowExecution.states[condition.value] || condition.value
                        end
    end

    # TODO: Refactor each case into it's own method
    case condition.operator
    when '='
      if metadata_field || condition.field == 'name'
        scope.where(node.matches(converted_value))
      else
        scope.where(node.eq(converted_value))
      end
    when 'in'
      if metadata_field
        scope.where(Arel::Nodes::NamedFunction.new('LOWER',
                                                   [node]).in(converted_value.map(&:downcase)))
      elsif condition.field == 'name'
        scope.where(node.lower.in(converted_value.map(&:downcase)))
      else
        scope.where(node.in(converted_value))
      end
    when '!='
      if metadata_field || condition.field == 'name'
        scope.where(node.eq(nil).or(node.does_not_match(converted_value)))
      else
        scope.where(node.not_eq(converted_value))
      end
    when 'not_in'
      if metadata_field
        scope.where(node.eq(nil).or(Arel::Nodes::NamedFunction.new('LOWER',
                                                                   [node]).not_in(converted_value.map(&:downcase))))
      elsif condition.field == 'name'
        scope.where(node.lower.not_in(converted_value.map(&:downcase)))
      else
        scope.where(node.not_in(converted_value))
      end
    when '<='
      if !metadata_field
        scope.where(node.lteq(converted_value))
      elsif metadata_key.end_with?('_date')
        scope
          .where(node.matches_regexp('^\d{4}(-\d{2}){0,2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
            ).lteq(converted_value)
          )
      else
        scope
          .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).lteq(converted_value)
          )
      end
    when '>='
      if !metadata_field
        scope.where(node.gteq(converted_value))
      elsif metadata_key.end_with?('_date')
        scope
          .where(node.matches_regexp('^\d{4}(-\d{2}){0,2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
            ).gteq(converted_value)
          )
      else
        scope
          .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).gteq(converted_value)
          )
      end
    when 'contains'
      scope.where(node.matches("%#{converted_value}%"))
    when 'not_contains'
      scope.where(node.does_not_match("%#{converted_value}%"))
    when 'exists'
      scope.where(node.not_eq(nil))
    when 'not_exists'
      scope.where(node.eq(nil))
    end
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
