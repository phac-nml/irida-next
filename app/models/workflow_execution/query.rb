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
  validates_with WorkflowExecutionSearchGroupValidator

  def initialize(attributes = {})
    attributes = attributes.dup
    @base_scope = attributes.delete(:base_scope) || attributes.delete('base_scope')
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
    sort_value = sort.presence || 'updated_at desc'
    column, _space, direction = sort_value.rpartition(' ')

    # Fallback to default if column is empty (e.g., if sort was just "desc")
    if column.blank?
      column = 'updated_at'
      direction = direction.presence || 'desc'
    end

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

  OPERATOR_HANDLERS = {
    '=' => :handle_equals,
    'in' => :handle_in,
    '!=' => :handle_not_equals,
    'not_in' => :handle_not_in,
    '<=' => :handle_less_than_equal,
    '>=' => :handle_greater_than_equal,
    'contains' => :handle_contains,
    'exists' => :handle_exists,
    'not_exists' => :handle_not_exists
  }.freeze

  private

  def pagy_results(limit, page)
    pagy(ransack_results, limit:, page:)
  end

  def non_pagy_results
    ransack_results
  end

  def ransack_results
    return WorkflowExecution.none unless valid?

    base_scope = @base_scope || WorkflowExecution.where(namespace_id:)
    scope = if advanced_query
              sort_workflow_executions(advanced_query_scope(base_scope))
            else
              sort_workflow_executions(base_scope)
            end

    scope.includes(namespace: :parent).ransack(ransack_params).result
  end

  def advanced_query_scope(base_scope = nil)
    query_base = base_scope || @base_scope || WorkflowExecution.where(namespace_id:)
    groups_scope = advanced_query_groups
    return query_base unless groups_scope

    query_base.and(groups_scope)
  end

  def advanced_query_groups
    adv_query_scope = nil
    groups.each do |group|
      next if group.empty?

      group_scope = WorkflowExecution.all
      group.conditions.each do |condition|
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

  def add_condition(scope, condition)
    field = normalized_field(condition)
    return scope if field.blank?

    node = build_arel_node(field)
    apply_operator(scope, condition, node, field)
  end

  def build_arel_node(field)
    return WorkflowExecution.arel_table[field] unless jsonb_field?(field)

    jsonb_key = field == 'workflow_name' ? 'pipeline_id' : 'workflow_version'
    Arel::Nodes::InfixOperation.new('->>', WorkflowExecution.arel_table[:metadata],
                                    Arel::Nodes::Quoted.new(jsonb_key))
  end

  def apply_operator(scope, condition, node, field)
    handler_method = OPERATOR_HANDLERS[condition.operator]
    return scope unless handler_method

    send(handler_method, scope, condition, node, field)
  end

  def handle_equals(scope, condition, node, field)
    jsonb_field = jsonb_field?(field)
    if jsonb_field || field == 'name'
      scope.where(node.matches(condition.value))
    elsif field == 'run_id'
      scope.where(node.eq(condition.value.upcase))
    else
      scope.where(node.eq(condition.value))
    end
  end

  def handle_in(scope, condition, node, field)
    jsonb_field = jsonb_field?(field)
    if jsonb_field || field == 'name'
      scope.where(node.matches_any(condition.value))
    elsif field == 'run_id'
      scope.where(node.in(condition.value.map(&:upcase)))
    else
      scope.where(node.in(condition.value))
    end
  end

  def handle_not_equals(scope, condition, node, field)
    jsonb_field = jsonb_field?(field)
    if jsonb_field || field == 'name'
      scope.where(node.eq(nil).or(node.does_not_match(condition.value)))
    elsif field == 'run_id'
      scope.where(node.not_eq(condition.value.upcase))
    else
      scope.where(node.not_eq(condition.value))
    end
  end

  def handle_not_in(scope, condition, node, field)
    jsonb_field = jsonb_field?(field)
    if jsonb_field || field == 'name'
      scope.where(node.eq(nil).or(node.does_not_match_all(condition.value)))
    elsif field == 'run_id'
      scope.where(node.not_in(condition.value.map(&:upcase)))
    else
      scope.where(node.not_in(condition.value))
    end
  end

  def handle_less_than_equal(scope, condition, node, field)
    jsonb_field = jsonb_field?(field)
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
  end

  def handle_greater_than_equal(scope, condition, node, field)
    jsonb_field = jsonb_field?(field)
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
  end

  def handle_contains(scope, condition, node, field)
    return scope if condition.value.blank?

    # UUID fields need to be cast to text before using ILIKE
    if field == 'id'
      text_node = Arel::Nodes::NamedFunction.new('CAST', [node.as(Arel::Nodes::SqlLiteral.new('TEXT'))])
      scope.where(text_node.matches("%#{condition.value}%"))
    else
      scope.where(node.matches("%#{condition.value}%"))
    end
  end

  def handle_exists(scope, _condition, node, _field)
    scope.where(node.not_eq(nil))
  end

  def handle_not_exists(scope, _condition, node, _field)
    scope.where(node.eq(nil))
  end

  def ransack_params
    {
      name_or_id_cont: name_or_id_cont
    }.compact
  end

  def sort_workflow_executions(scope)
    return scope unless column.present? && direction.present?

    if column.starts_with? 'metadata.'
      field = column.gsub('metadata.', '')
      scope.order(WorkflowExecution.metadata_sort(field, direction))
    else
      scope.order("#{column} #{direction}")
    end
  end

  def normalized_field(condition)
    condition.field.to_s.sub(/\Ametadata\./, '')
  end

  def jsonb_field?(field)
    %w[workflow_name workflow_version].include?(field)
  end
end
