# frozen_string_literal: true

# model to represent sample search form
class Sample::Query # rubocop:disable Style/ClassAndModuleChildren, Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend

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
    Sample.with(
      namespace_samples: Sample.where(project_id: project_ids).select(:id),
      filtered_samples: advanced_query_groups
    ).where(
      Arel.sql('samples.id in (select * from namespace_samples) and id in (select id from filtered_samples)')
    )
  end

  def advanced_query_groups
    or_conditions = []
    groups.each do |group|
      group_scope = Sample.all
      group.conditions.map do |condition|
        group_scope = add_condition(group_scope, condition)
      end
      or_conditions << group_scope
    end
    or_conditions
  end

  def add_condition(scope, condition) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    metadata_field = condition.field.starts_with? 'metadata.'
    metadata_key = (condition.field.gsub(/^metadata./, '') if metadata_field)
    node = if metadata_field
             Arel::Nodes::InfixOperation.new('->>', Sample.arel_table[:metadata],
                                             Arel::Nodes::Quoted.new(metadata_key))
           else
             Sample.arel_table[condition.field]
           end

    # TODO: Refactor each case into it's own method
    case condition.operator
    when '='
      if metadata_field || %w[name puid].include?(condition.field)
        scope.where(node.matches(condition.value))
      else
        scope.where(node.eq(condition.value))
      end
    when 'in'
      if metadata_field || %w[name puid].include?(condition.field)
        scope.where(node.matches_any(condition.value))
      else
        scope.where(node.in(condition.value))
      end
    when '!='
      if metadata_field || %w[name puid].include?(condition.field)
        scope.where(node.does_not_match(condition.value))
      else
        scope.where(node.not_eq(condition.value))
      end
    when 'not_in'
      if metadata_field || %w[name puid].include?(condition.field)
        scope.where(node.does_not_match_all(condition.value))
      else
        scope.where(node.not_in(condition.value))
      end
    when '<='
      if !metadata_field
        scope.where(node.lteq(condition.value))
      elsif metadata_key.end_with?('_date')
        scope
          .where(node.matches_regexp('^\d{4}(-\d{2}){0,2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
            ).lteq(condition.value)
          )
      else
        scope
          .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).lteq(condition.value)
          )
      end
    when '>='
      if !metadata_field
        scope.where(node.gteq(condition.value))
      elsif metadata_key.end_with?('_date')
        scope
          .where(node.matches_regexp('^\d{4}(-\d{2}){0,2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
            ).gteq(condition.value)
          )
      else
        scope
          .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
            ).gteq(condition.value)
          )
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
