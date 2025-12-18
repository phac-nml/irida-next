# frozen_string_literal: true

# model to represent sample search form
class Sample::Query # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedSearchable
  include AdvancedSearchConditions
  include AdvancedSearchConditionDispatcher
  prepend SortableQuery
  include AdvancedSearchQuery

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

  private

  def model_class
    Sample
  end

  def filter_column
    :project_id
  end

  def filter_ids
    project_ids
  end

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
