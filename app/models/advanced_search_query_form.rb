# frozen_string_literal: true

# Base query-form object for models that support:
# - basic filtering via IDs
# - advanced search groups/conditions
# - sorting (including metadata.*)
# - optional pagination
#
# Subclasses are expected to define:
# - `filter_column` and `filter_ids`
# - `model_class`
# - `ransack_params`
# - any custom normalization/overrides for advanced conditions
class AdvancedSearchQueryForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend

  include AdvancedSearch::Form
  include AdvancedSearch::Operators
  include AdvancedSearch::Filtering
  include AdvancedSearch::Querying

  prepend SortableQuery

  attribute :column, :string
  attribute :direction, :string
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  class_attribute :filter_column_attribute, instance_accessor: false, default: nil
  class_attribute :filter_ids_attribute, instance_accessor: false, default: nil
  class_attribute :model_class_attribute, instance_accessor: false, default: nil
  class_attribute :allowed_sort_columns_attribute, instance_accessor: false, default: [].freeze

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :column, inclusion: { in: ->(record) { record.send(:allowed_sort_columns) } }

  def self.allowed_sort_columns(*columns)
    self.allowed_sort_columns_attribute = columns.flatten.map(&:to_s).freeze
  end

  def self.validates_filter_ids(attribute)
    self.filter_ids_attribute = attribute
    validates attribute, length: { minimum: 1 }
  end

  def self.filter_by(column, ids:)
    self.filter_column_attribute = column
    validates_filter_ids(ids)
  end

  def self.query_for(model_class)
    self.model_class_attribute = model_class
  end

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
    self.class.allowed_sort_columns_attribute + [column].select { |c| c&.start_with?('metadata.') }
  end

  def filter_column
    column_name = self.class.filter_column_attribute
    return column_name if column_name

    raise NotImplementedError, "Define filter_column or call filter_by in #{self.class.name}"
  end

  def filter_ids
    attribute_name = self.class.filter_ids_attribute
    return public_send(attribute_name) if attribute_name

    raise NotImplementedError, "Define filter_ids or call validates_filter_ids/filter_by in #{self.class.name}"
  end

  def model_class
    klass = self.class.model_class_attribute
    return klass if klass

    raise NotImplementedError, "Define model_class or call query_for in #{self.class.name}"
  end

  def search_scope
    @scope || model_class
  end
end
