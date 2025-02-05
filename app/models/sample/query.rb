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
          condition_params[:value] = condition_params[:value].compact_blank if condition_params[:value].is_a?(Array)
          Rails.logger.debug 'Debug Here'
          Rails.logger.debug condition_params[:value]
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
    if advanced_query && ENV['RANSACK_ONLY_SEARCH'].blank?
      pagy_searchkick(searchkick_pagy_results, limit:, page:)
    else
      pagy(ransack_results, limit:, page:)
    end
  end

  def non_pagy_results
    if advanced_query && ENV['RANSACK_ONLY_SEARCH'].blank?
      searchkick_results
    else
      ransack_results
    end
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
          .where(node.matches_regexp('^\d{4}-\d{2}-\d{2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DATE'))]
            ).lteq(condition.value)
          )
      else
        scope
          .where(node.matches_regexp('^\d+\.?\d+$'))
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
          .where(node.matches_regexp('^\d{4}-\d{2}-\d{2}$'))
          .where(
            Arel::Nodes::NamedFunction.new(
              'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DATE'))]
            ).gteq(condition.value)
          )
      else
        scope
          .where(node.matches_regexp('^\d+\.?\d+$'))
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

  def searchkick_pagy_results
    return Sample.pagy_search('') unless valid?

    Sample.pagy_search(name_or_puid_cont.presence || '*', **searchkick_kwargs)
  end

  def searchkick_results
    return Sample.search('') unless valid?

    Sample.search(name_or_puid_cont.presence || '*', **searchkick_kwargs)
  end

  def searchkick_kwargs
    { fields: [{ name: :text_middle }, { puid: :text_middle }],
      misspellings: false,
      where: { project_id: project_ids }.merge((
       if name_or_puid_in.present?
         { _or: [{ name: name_or_puid_in },
                 { puid: name_or_puid_in }] }
       else
         {}
       end
     )).merge(advanced_search_params),
      order: { "#{column}": { order: direction, unmapped_type: 'long' } },
      includes: [project: { namespace: [{ parent: :route }, :route] }] }
  end

  def advanced_search_params
    or_conditions = []
    groups.each do |group|
      and_conditions = {}
      group.conditions.map do |condition|
        handle_condition(and_conditions, condition)
      end
      or_conditions << and_conditions
    end
    { _or: or_conditions }
  end

  def handle_condition(and_conditions, condition) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    key = condition.field.gsub(/(?<!^metadata)\./, '___')
    case condition.operator
    when '=', 'in'
      and_conditions[key] = condition.value
    when '!=', 'not_in'
      and_conditions[key] = { not: condition.value }
    when '<='
      handle_between_condition(and_conditions, condition, key, :lte)
    when '>='
      handle_between_condition(and_conditions, condition, key, :gte)
    when 'contains'
      and_conditions[key] = { ilike: "%#{condition.value}%" }
    when 'exists'
      and_conditions[key] = { not: nil }
    when 'not_exists'
      and_conditions[key] = nil
    end
  end

  def handle_between_condition(and_conditions, condition, key, operation) # rubocop:disable Metrics/AbcSize
    if %w[created_at updated_at attachments_updated_at].include?(condition.field) || condition.field.end_with?('_date')
      and_conditions[key] = if and_conditions[key].nil?
                              { operation => condition.value }
                            else
                              and_conditions[key].merge({ operation => condition.value })
                            end
    else
      and_conditions["#{key}.numeric"] = if and_conditions["#{key}.numeric"].nil?
                                           { operation => condition.value.to_i }
                                         else
                                           and_conditions["#{key}.numeric"]
                                             .merge({ operation => condition.value.to_i })
                                         end
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
