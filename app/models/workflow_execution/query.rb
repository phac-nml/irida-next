# frozen_string_literal: true

# Model representing an advanced search query for workflow executions.
#
# This query builder supports both simple text-based searches and complex advanced searches
# with multiple conditions and groups. It handles JSONB metadata fields, enum fields,
# date fields, and provides pagination support.
#
# @example Simple search by name or ID
#   query = WorkflowExecution::Query.new(name_or_id_cont: 'example')
#   pagy, results = query.results(limit: 20, page: 1)
#
# @example Advanced search with conditions
#   query = WorkflowExecution::Query.new(
#     groups_attributes: {
#       '0': {
#         conditions_attributes: {
#           '0': { field: 'state', operator: '=', value: 'completed' },
#           '1': { field: 'workflow_name', operator: 'contains', value: 'iridanext' }
#         }
#       }
#     }
#   )
#   pagy, results = query.results(limit: 20, page: 1)
#
# @see WorkflowExecution::SearchGroup
# @see WorkflowExecution::SearchCondition
# @see AdvancedQuerySearchable
class WorkflowExecution::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedQuerySearchable

  METADATA_FIELD_MAP = {
    'workflow_name' => 'pipeline_id',
    'workflow_version' => 'workflow_version'
  }.freeze

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
    parsed_groups = attributes.each_value.map do |group_attributes|
      parsed_conditions = group_attributes.each_value.flat_map do |conditions_attributes|
        conditions_attributes.each_value.map do |condition_params|
          WorkflowExecution::SearchCondition.new(condition_params)
        end
      end

      WorkflowExecution::SearchGroup.new(conditions: parsed_conditions)
    end

    assign_attributes(groups: parsed_groups)
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

    # Eager load associations to prevent N+1 queries in the table view
    # - namespace and parent: for namespace display
    # Note: workflow is not an association but a method that looks up from Irida::Pipelines
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
    field = normalized_field(condition.field)
    return scope if field.blank?

    node = build_arel_node(field)
    apply_operator(scope, condition, node, field)
  end

  def build_arel_node(field)
    if jsonb_field?(field)
      jsonb_key = METADATA_FIELD_MAP.fetch(field)
      Arel::Nodes::InfixOperation.new(
        '->>', WorkflowExecution.arel_table[:metadata], Arel::Nodes::Quoted.new(jsonb_key)
      )
    else
      WorkflowExecution.arel_table[field.to_sym]
    end
  end

  def text_match_field?(field)
    jsonb_field?(field) || field == 'name'
  end

  def uppercase_field?(field)
    field == 'run_id'
  end

  def uuid_field?(field)
    field == 'id'
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

  def normalized_field(field)
    field.to_s.sub(/\Ametadata\./, '')
  end

  def jsonb_field?(field)
    METADATA_FIELD_MAP.key?(field)
  end

  # Override handle_equals to convert workflow names to pipeline_ids
  def handle_equals(scope, condition, node, field)
    if field == 'workflow_name'
      pipeline_id = workflow_name_to_pipeline_id(condition.value)
      return scope if pipeline_id.nil?

      scope.where(node.eq(pipeline_id))
    else
      super
    end
  end

  # Override handle_in to convert workflow names to pipeline_ids
  def handle_in(scope, condition, node, field)
    if field == 'workflow_name'
      pipeline_ids = condition.value.filter_map { |name| workflow_name_to_pipeline_id(name) }
      return scope if pipeline_ids.empty?

      scope.where(node.in(pipeline_ids))
    else
      super
    end
  end

  # Override handle_not_equals to convert workflow names to pipeline_ids
  def handle_not_equals(scope, condition, node, field)
    if field == 'workflow_name'
      pipeline_id = workflow_name_to_pipeline_id(condition.value)
      return scope if pipeline_id.nil?

      scope.where(node.not_eq(pipeline_id))
    else
      super
    end
  end

  # Override handle_not_in to convert workflow names to pipeline_ids
  def handle_not_in(scope, condition, node, field)
    if field == 'workflow_name'
      pipeline_ids = condition.value.filter_map { |name| workflow_name_to_pipeline_id(name) }
      return scope if pipeline_ids.empty?

      scope.where(node.not_in(pipeline_ids))
    else
      super
    end
  end

  # Override handle_contains to search workflow names and convert to pipeline_ids
  def handle_contains(scope, condition, node, field)
    if field == 'workflow_name'
      return scope if condition.value.blank?

      # Find all pipeline_ids whose names contain the search term
      pipelines = Irida::Pipelines.instance.pipelines('executable')
      search_term = condition.value.downcase
      matching_pipeline_ids = pipelines.filter_map do |_pipeline_id, p|
        next unless p.name.is_a?(Hash)

        # Check all locale values for matches
        p.pipeline_id if p.name.values.any? { |name| name&.downcase&.include?(search_term) }
      end

      return scope if matching_pipeline_ids.empty?

      scope.where(node.in(matching_pipeline_ids))
    else
      super
    end
  end

  # Convert workflow name to pipeline_id
  def workflow_name_to_pipeline_id(workflow_name)
    return nil if workflow_name.blank?

    pipelines = Irida::Pipelines.instance.pipelines('executable')
    pipeline = pipelines.find do |_pipeline_id, p|
      next false unless p.name.is_a?(Hash)

      # Check current locale first, then all locales as fallback
      p.name[I18n.locale.to_s] == workflow_name || p.name.values.include?(workflow_name)
    end

    pipeline&.last&.pipeline_id
  end
end
