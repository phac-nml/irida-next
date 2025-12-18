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

  def apply_equals_operator(scope, node, value, metadata_field:, field_name:)
    return super unless field_name == 'puid' && !metadata_field

    scope.where(node.eq(value.upcase))
  end

  def apply_in_operator(scope, node, value, metadata_field:, field_name:)
    return super unless field_name == 'puid' && !metadata_field

    scope.where(node.in(value.map(&:upcase)))
  end

  def apply_not_equals_operator(scope, node, value, metadata_field:, field_name:)
    return super unless field_name == 'puid' && !metadata_field

    scope.where(node.not_eq(value.upcase))
  end

  def apply_not_in_operator(scope, node, value, metadata_field:, field_name:)
    return super unless field_name == 'puid' && !metadata_field

    scope.where(node.not_in(value.map(&:upcase)))
  end

  def ransack_params
    {
      name_or_puid_cont: name_or_puid_cont,
      name_or_puid_in: name_or_puid_in
    }.compact
  end
end
