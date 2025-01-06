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
  attribute :groups, default: -> { [] }
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :project_ids, length: { minimum: 1 }

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
          conditions.push(Sample::Condition.new(condition_params))
        end
      end
      groups.push(Sample::Group.new(conditions:))
    end
    assign_attributes(groups:)
  end

  def sort=(value)
    super
    column, direction = sort.split
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
      advanced_query ? searchkick_results : ransack_results
    end
  end

  private

  def pagy_results(limit, page)
    if advanced_query
      pagy_searchkick(searchkick_pagy_results, limit:, page:)
    else
      pagy(ransack_results, limit:, page:)
    end
  end

  def ransack_results
    return Sample.none unless valid?

    sort_samples.ransack(ransack_params).result
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

  def advanced_search_params # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    or_conditions = []
    groups.each do |group|
      and_conditions = {}
      group.conditions.map do |condition|
        case condition.operator
        when '='
          and_conditions[condition.field] = condition.value.split(/,\s|,/)
        when '!='
          and_conditions[condition.field] = { not: condition.value.split(/,\s|,/) }
        when '<='
          between_advanced_search_params(and_conditions, condition, :lte)
        when '>='
          between_advanced_search_params(and_conditions, condition, :gte)
        when 'contains'
          and_conditions[condition.field] = { ilike: "%#{condition.value}%" }
        end
      end
      or_conditions << and_conditions
    end
    { _or: or_conditions }
  end

  def between_advanced_search_params(and_conditions, condition, operation) # rubocop:disable Metrics/AbcSize
    if condition.field.end_with?('_date')
      and_conditions[condition.field] = if and_conditions[condition.field].nil?
                                          { operation => condition.value }
                                        else
                                          and_conditions[condition.field].merge({ operation => condition.value })
                                        end
    else
      and_conditions["#{condition.field}.numeric"] = if and_conditions["#{condition.field}.numeric"].nil?
                                                       { operation => condition.value.to_i }
                                                     else
                                                       and_conditions["#{condition.field}.numeric"]
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
