# frozen_string_literal: true

# model to represent workflow execution search form
class WorkflowExecution::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend

  ResultTypeError = Class.new(StandardError)

  attribute :column, :string
  attribute :direction, :string
  attribute :name_or_id_cont, :string
  attribute :namespace_id, :string
  attribute :groups, default: lambda {
    [WorkflowExecution::SearchGroup.new(
      conditions: [WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')]
    )]
  }
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :namespace_id, presence: true
  validates_with WorkflowExecutionSearchGroupValidator

  def initialize(...)
    super
    self.sort = sort
    self.advanced_query = advanced_query?
    self.groups = groups
  end

  def groups_attributes=(attributes)
    groups ||= []
    attributes.each_value do |group_attributes|
      conditions ||= []
      group_attributes.each_value do |conditions_attributes|
        conditions_attributes.each_value do |condition_params|
          conditions.push(WorkflowExecution::SearchCondition.new(condition_params))
        end
      end
      groups.push(WorkflowExecution::SearchGroup.new(conditions:))
    end
    assign_attributes(groups:)
  end

  def sort=(value)
    super
    # use rpartition to split on the first space encountered from the right side
    # this allows us to sort by metadata fields which contain spaces
    column, _space, direction = sort.rpartition(' ')
    column = column.gsub('metadata_', 'metadata.') if column.match?(/metadata_/)
    assign_attributes(column:, direction:)
  end

  def advanced_query?
    return !groups.all?(&:empty?) if groups

    false
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

    scope.includes(namespace: :parent).ransack(ransack_params).result
  end

  def advanced_query_scope
    WorkflowExecution.where(namespace_id:).and(advanced_query_groups)
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
    # Map workflow_name to metadata->>'pipeline_id' and workflow_version to metadata->>'workflow_version'
    jsonb_field = %w[workflow_name workflow_version].include?(condition.field)
    jsonb_key = if condition.field == 'workflow_name'
                  'pipeline_id'
                elsif condition.field == 'workflow_version'
                  'workflow_version'
                end

    node = if jsonb_field
             Arel::Nodes::InfixOperation.new('->>', WorkflowExecution.arel_table[:metadata],
                                             Arel::Nodes::Quoted.new(jsonb_key))
           else
             WorkflowExecution.arel_table[condition.field]
           end

    # TODO: Refactor each case into it's own method
    case condition.operator
    when '='
      if jsonb_field || condition.field == 'name'
        scope.where(node.matches(condition.value))
      elsif condition.field == 'run_id'
        scope.where(node.eq(condition.value.upcase))
      else
        scope.where(node.eq(condition.value))
      end
    when 'in'
      if jsonb_field || condition.field == 'name'
        scope.where(node.matches_any(condition.value))
      elsif condition.field == 'run_id'
        scope.where(node.in(condition.value.map(&:upcase)))
      else
        scope.where(node.in(condition.value))
      end
    when '!='
      if jsonb_field || condition.field == 'name'
        scope.where(node.eq(nil).or(node.does_not_match(condition.value)))
      elsif condition.field == 'run_id'
        scope.where(node.not_eq(condition.value.upcase))
      else
        scope.where(node.not_eq(condition.value))
      end
    when 'not_in'
      if jsonb_field || condition.field == 'name'
        scope.where(node.eq(nil).or(node.does_not_match_all(condition.value)))
      elsif condition.field == 'run_id'
        scope.where(node.not_in(condition.value.map(&:upcase)))
      else
        scope.where(node.not_in(condition.value))
      end
    when '<='
      if jsonb_field
        scope
          .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).lteq(condition.value)
          )
      else
        scope.where(node.lteq(condition.value))
      end
    when '>='
      if jsonb_field
        scope
          .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).gteq(condition.value)
          )
      else
        scope.where(node.gteq(condition.value))
      end
    when 'contains'
      scope.where(node.matches("%#{condition.value}%"))
    when 'exists'
      scope.where(node.not_eq(nil))
    when 'not_exists'
      scope.where(node.eq(nil))
    end
  end

  def ransack_params
    {
      name_or_id_cont: name_or_id_cont
    }.compact
  end

  def sort_workflow_executions(scope = WorkflowExecution.where(namespace_id:))
    if column.starts_with? 'metadata.'
      field = column.gsub('metadata.', '')
      scope.order(WorkflowExecution.metadata_sort(field, direction))
    else
      scope.order("#{column} #{direction}")
    end
  end
end
