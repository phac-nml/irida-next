# frozen_string_literal: true

module AdvancedSearch
  # Immutable description of a single advanced-search filter operator.
  #
  # This is a pure data object; it never evaluates feature flags or touches
  # Active Record. Consumers (filtering, validation, UI, GraphQL) read these
  # attributes from {AdvancedSearch::OperatorCatalog} so that every operator is
  # declared exactly once.
  #
  # Attributes:
  # - key: canonical, persisted operator string (e.g. "=", "text_equals"). Never renamed.
  # - arel_handler: method on AdvancedSearch::Operators used to build the Arel condition.
  # - arel_args: ordered argument tokens passed after (scope, node). Reserved tokens
  #   (:value, :field_name, :model_class, :metadata_key) are resolved by the dispatcher;
  #   any other value is forwarded literally (e.g. :eq, :gteq, :date).
  # - ui_group: which option group the operator renders in
  #   (:standard, :metadata_text, :metadata_numeric, :metadata_date).
  # - graphql_name: GraphQL enum name, or nil when the operator is not exposed in GraphQL.
  # - graphql_group: :standard or :metadata, used to pick the GraphQL enum description.
  # - metadata_data_type: :text, :numeric, :date, or nil for standard operators.
  # - combinable_group: symbol shared by operators that may co-exist on one field, or nil.
  # - requires_metadata_flag: operator only exists when :advanced_search_metadata_operators is on.
  # - exists: operator is an existence check (ignores value).
  # - between: operator expects a two-element range value.
  # - non_metadata: member of the "non metadata" operator set (standard field operators).
  # - numeric_value: valid for fields that only accept numeric values.
  # - enum_standard: standard operator allowed on enum fields.
  # - enum_metadata: metadata operator allowed on enum fields.
  # - standard_date_disallowed: standard operator that may not be used on a standard date field.
  Operator = Data.define(
    :key,
    :arel_handler,
    :arel_args,
    :ui_group,
    :graphql_name,
    :graphql_group,
    :metadata_data_type,
    :combinable_group,
    :requires_metadata_flag,
    :exists,
    :between,
    :non_metadata,
    :numeric_value,
    :enum_standard,
    :enum_metadata,
    :standard_date_disallowed
  ) do
    def metadata?
      requires_metadata_flag
    end

    def exists?
      exists
    end

    def between?
      between
    end

    def graphql?
      !graphql_name.nil?
    end
  end
end
