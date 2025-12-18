# frozen_string_literal: true

# model to represent sample search form
class Sample::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  ResultTypeError = Class.new(StandardError)

  allowed_sort_columns :name, :puid, :created_at, :updated_at, :attachments_updated_at

  attribute :name_or_puid_cont, :string
  attribute :name_or_puid_in, default: -> { [] }
  attribute :project_ids, default: -> { [] }
  attribute :groups, default: lambda {
    [Sample::SearchGroup.new(conditions: [Sample::SearchCondition.new(field: '', operator: '', value: '')])]
  }

  query_for Sample
  filter_by :project_id, ids: :project_ids
  validates_with AdvancedSearchGroupValidator

  private

  def normalize_condition_value(condition)
    return condition.value unless condition.field == 'puid'
    return condition.value if condition.field.starts_with?('metadata.')

    case condition.operator
    when 'in', 'not_in'
      Array(condition.value).map { |v| v.to_s.upcase }
    when '=', '!='
      condition.value.to_s.upcase
    else
      condition.value
    end
  end

  def ransack_params
    {
      name_or_puid_cont: name_or_puid_cont,
      name_or_puid_in: name_or_puid_in
    }.compact
  end
end
