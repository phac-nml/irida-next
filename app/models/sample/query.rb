# frozen_string_literal: true

# model to represent sample search form
class Sample::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedSearchable
  include AdvancedSearchConditions

  ResultTypeError = Class.new(StandardError)

  ALLOWED_SORT_COLUMNS = %w[name puid created_at updated_at attachments_updated_at].freeze

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
  validates :column, inclusion: {
    in: lambda { |record|
      ALLOWED_SORT_COLUMNS + [record.column].select { |c| c&.start_with?('metadata.') }
    }
  }
  validates_with AdvancedSearchGroupValidator

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

  def add_condition(scope, condition) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    node = build_arel_node(condition, Sample)
    value = condition.value
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
    else
      scope
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

  def handle_equals_operator(scope, node, value, metadata_field:, field_name:)
    if metadata_field || field_name == 'name'
      condition_equals(scope, node, value, metadata_field:, field_name:)
    elsif field_name == 'puid'
      scope.where(node.eq(value.upcase))
    else
      scope.where(node.eq(value))
    end
  end

  def handle_in_operator(scope, node, value, metadata_field:, field_name:)
    if metadata_field || field_name == 'name'
      condition_in(scope, node, value, metadata_field:, field_name:)
    elsif field_name == 'puid'
      scope.where(node.in(value.map(&:upcase)))
    else
      scope.where(node.in(value))
    end
  end

  def handle_not_equals_operator(scope, node, value, metadata_field:, field_name:)
    if metadata_field || field_name == 'name'
      condition_not_equals(scope, node, value, metadata_field:, field_name:)
    elsif field_name == 'puid'
      scope.where(node.not_eq(value.upcase))
    else
      scope.where(node.not_eq(value))
    end
  end

  def handle_not_in_operator(scope, node, value, metadata_field:, field_name:)
    if metadata_field || field_name == 'name'
      condition_not_in(scope, node, value, metadata_field:, field_name:)
    elsif field_name == 'puid'
      scope.where(node.not_in(value.map(&:upcase)))
    else
      scope.where(node.not_in(value))
    end
  end

  def ransack_params
    {
      name_or_puid_cont: name_or_puid_cont,
      name_or_puid_in: name_or_puid_in
    }.compact
  end

  def sort_samples(scope = Sample.where(project_id: project_ids))
    ordered_scope = if column.starts_with? 'metadata.'
                      field = column.gsub('metadata.', '')
                      scope.order(Sample.metadata_sort(field, direction))
                    else
                      scope.order(Arel.sql(column) => direction.to_sym)
                    end

    # add in tie breaker sort
    return ordered_scope if column == 'id'

    ordered_scope.order(id: direction.to_sym)
  end
end
