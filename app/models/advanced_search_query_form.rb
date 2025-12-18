# frozen_string_literal: true

# Base query-form object for models that support:
# - basic filtering via IDs
# - advanced search groups/conditions
# - sorting (including metadata.*)
# - optional pagination
#
# Subclasses are expected to define:
# - `ALLOWED_SORT_COLUMNS`
# - `filter_column` and `filter_ids`
# - `model_class`
# - `ransack_params`
# - any custom normalization/overrides for advanced conditions
class AdvancedSearchQueryForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend

  include AdvancedSearchable
  include AdvancedSearchConditions
  include AdvancedSearchConditionDispatcher
  include AdvancedSearchQuery

  prepend SortableQuery

  attribute :column, :string
  attribute :direction, :string
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :column, inclusion: { in: ->(record) { record.send(:allowed_sort_columns) } }

  def initialize(attributes = nil, scope: nil, **kwargs)
    attributes = attributes.to_h if attributes.respond_to?(:to_h)
    attributes ||= {}
    attributes = attributes.presence ? attributes.merge(kwargs) : kwargs

    super(attributes)
    @scope = scope

    self.sort = sort
    self.advanced_query = advanced_query?
    self.groups = groups if respond_to?(:groups=)
  end

  private

  def allowed_sort_columns
    self.class::ALLOWED_SORT_COLUMNS + [column].select { |c| c&.start_with?('metadata.') }
  end

  def search_scope
    @scope || model_class
  end
end
