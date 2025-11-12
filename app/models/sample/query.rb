# frozen_string_literal: true

# model to represent sample search form
class Sample::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedQuerySearchable

  ResultTypeError = Class.new(StandardError)

  attribute :column, :string
  attribute :direction, :string
  attribute :name_or_puid_cont, :string
  attribute :name_or_puid_in, default: -> { [] }
  attribute :project_ids, default: -> { [] }
  attribute :groups, default: lambda {
    [Sample::SearchGroup.new(conditions: [Sample::SearchCondition.new(field: '', operator: '', value: '')])]
  }
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :project_ids, length: { minimum: 1 }
  validates_with AdvancedSearchGroupValidator

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
          conditions.push(Sample::SearchCondition.new(condition_params))
        end
      end
      groups.push(Sample::SearchGroup.new(conditions:))
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
    return Sample.none unless valid?

    scope = if advanced_query
              sort_samples(advanced_query_scope)
            else
              sort_samples
            end

    scope.ransack(ransack_params).result
  end

  def advanced_query_scope
    Sample.where(project_id: project_ids).and(advanced_query_groups)
  end

  def advanced_query_groups
    adv_query_scope = nil
    groups.each do |group|
      group_scope = Sample
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

  def add_condition(scope, condition)
    is_metadata = condition.field.starts_with?('metadata.')
    field = is_metadata ? condition.field.gsub(/^metadata./, '') : condition.field
    return scope if field.blank?

    node = build_arel_node(condition)
    apply_operator(scope, condition, node, field)
  end

  def build_arel_node(condition)
    if condition.field.starts_with?('metadata.')
      metadata_key = condition.field.gsub(/^metadata./, '')
      Arel::Nodes::InfixOperation.new('->>', Sample.arel_table[:metadata],
                                      Arel::Nodes::Quoted.new(metadata_key))
    else
      Sample.arel_table[condition.field]
    end
  end

  def text_match_field?(field)
    field == 'name'
  end

  def uppercase_field?(field)
    field == 'puid'
  end

  def jsonb_field?(_field)
    # Field has already been normalized at this point
    # We need to track this separately in add_condition
    false
  end

  def date_field?(field)
    field.end_with?('_date')
  end

  # Override to handle metadata field detection properly
  def handle_less_than_equal(scope, condition, node, _field)
    if condition.field.starts_with?('metadata.')
      metadata_key = condition.field.gsub(/^metadata./, '')
      if metadata_key.end_with?('_date')
        handle_jsonb_date_comparison(scope, node, condition.value, :lteq)
      else
        handle_jsonb_numeric_comparison(scope, node, condition.value, :lteq)
      end
    else
      scope.where(node.lteq(condition.value))
    end
  end

  # Override to handle metadata field detection properly
  def handle_greater_than_equal(scope, condition, node, _field)
    if condition.field.starts_with?('metadata.')
      metadata_key = condition.field.gsub(/^metadata./, '')
      if metadata_key.end_with?('_date')
        handle_jsonb_date_comparison(scope, node, condition.value, :gteq)
      else
        handle_jsonb_numeric_comparison(scope, node, condition.value, :gteq)
      end
    else
      scope.where(node.gteq(condition.value))
    end
  end

  # Override to also check metadata fields
  def handle_equals(scope, condition, node, field)
    if condition.field.starts_with?('metadata.') || field == 'name'
      scope.where(node.matches(condition.value))
    elsif field == 'puid'
      scope.where(node.eq(condition.value.upcase))
    else
      scope.where(node.eq(condition.value))
    end
  end

  # Override to also check metadata fields
  def handle_in(scope, condition, node, field)
    if condition.field.starts_with?('metadata.') || field == 'name'
      scope.where(node.matches_any(condition.value))
    elsif field == 'puid'
      scope.where(node.in(condition.value.map(&:upcase)))
    else
      scope.where(node.in(condition.value))
    end
  end

  # Override to also check metadata fields
  def handle_not_equals(scope, condition, node, field)
    if condition.field.starts_with?('metadata.') || field == 'name'
      scope.where(node.eq(nil).or(node.does_not_match(condition.value)))
    elsif field == 'puid'
      scope.where(node.not_eq(condition.value.upcase))
    else
      scope.where(node.not_eq(condition.value))
    end
  end

  # Override to also check metadata fields
  def handle_not_in(scope, condition, node, field)
    if condition.field.starts_with?('metadata.') || field == 'name'
      scope.where(node.eq(nil).or(node.does_not_match_all(condition.value)))
    elsif field == 'puid'
      scope.where(node.not_in(condition.value.map(&:upcase)))
    else
      scope.where(node.not_in(condition.value))
    end
  end

  def ransack_params
    {
      name_or_puid_cont: name_or_puid_cont,
      name_or_puid_in: name_or_puid_in
    }.compact
  end

  def sort_samples(scope = Sample.where(project_id: project_ids))
    if column.starts_with? 'metadata.'
      field = column.gsub('metadata.', '')
      scope.order(Sample.metadata_sort(field, direction))
    else
      scope.order("#{column} #{direction}")
    end
  end
end
