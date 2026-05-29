# frozen_string_literal: true

# model to represent sample search form
class Sample::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  class ResultTypeError < StandardError
  end

  allowed_sort_columns :name, :puid, :created_at, :updated_at, :attachments_updated_at, 'namespaces.puid'

  attribute :name_or_puid_cont, :string
  attribute :project_ids, default: -> { [] }
  attribute :groups, default: -> { [] }

  query_for Sample
  filter_by :project_id, ids: :project_ids
  validates_with Sample::AdvancedSearchGroupValidator

  def search_group_class
    Sample::SearchGroup
  end

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
      name_or_puid_cont: name_or_puid_cont
    }.compact
  end
end
