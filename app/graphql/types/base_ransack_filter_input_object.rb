# frozen_string_literal: true

module Types
  # Base Ransack Filter Input Object
  class BaseRansackFilterInputObject < BaseInputObject
    DEFAULT_EXCLUDED_ATTRIBUTES = %w[id metadata deleted_at].freeze
    JSONB_PREDICATE_KEYS = %w[jcont jcont_all jcont_any jcont_key jcont_key_all jcont_key_any].freeze

    def self.default_predicate_keys
      Ransack.predicates.keys.excluding(JSONB_PREDICATE_KEYS)
    end
  end

  class SampleAdvancedSearchConditionOperatorInputType < BaseEnum # rubocop:disable Style/Documentation
    METADATA_OPERATORS_FOR_ENUM = {
      'DATE_GREATER_THAN_EQUALS' => 'date_greater_than_equals',
      'DATE_LESS_THAN_EQUALS' => 'date_less_than_equals',
      'DATE_EQUALS' => 'date_equals',
      'DATE_NOT_EQUALS' => 'date_not_equals',
      'NUMERIC_GREATER_THAN_EQUALS' => 'numeric_greater_than_equals',
      'NUMERIC_LESS_THAN_EQUALS' => 'numeric_less_than_equals',
      'NUMERIC_EQUALS' => 'numeric_equals',
      'NUMERIC_NOT_EQUALS' => 'numeric_not_equals',
      'TEXT_EQUALS' => 'text_equals',
      'TEXT_NOT_EQUALS' => 'text_not_equals',
      'TEXT_IN' => 'text_in',
      'TEXT_NOT_IN' => 'text_not_in',
      'TEXT_CONTAINS' => 'text_contains',
      'TEXT_NOT_CONTAINS' => 'text_not_contains'
    }.freeze

    graphql_name 'SampleAdvancedSearchConditionOperator'
    description 'Sample Advanced Search Condition Operator'

    value 'EQUALS', value: '='
    value 'NOT_EQUALS', value: '!='
    value 'LESS_THAN_EQUALS', value: '<='
    value 'GREATER_THAN_EQUALS', value: '>='
    value 'CONTAINS', value: 'contains'
    value 'NOT_CONTAINS', value: 'not_contains'
    value 'EXISTS', value: 'exists'
    value 'NOT_EXISTS', value: 'not_exists'
    value 'IN', value: 'in'
    value 'NOT_IN', value: 'not_in'

    # only enable metadata operators and standard operator descriptions with enabled feature flag
    def self.enum_values(context)
      all_values = super
      return all_values unless Flipper.enabled?(:advanced_search_metadata_operators)

      METADATA_OPERATORS_FOR_ENUM.each do |enum_name, enum_value|
        all_values << GraphQL::Schema::EnumValue.new(enum_name, description: 'Use to filter metadata fields',
                                                                value: enum_value, owner: self)
      end
      all_values
    end
  end

  class ValueScalar < BaseScalar # rubocop:disable Style/Documentation
    description 'Sample Advanced Search Condition Value'

    def self.coerce_input(value, _context)
      return value if value.is_a?(String) || (value.is_a?(Array) && value.all?(String))

      raise GraphQL::CoercionError, I18n.t('graphql.value_scalar.error', value: value.inspect)
    end
  end

  class SampleAdvancedSearchConditionInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'SampleAdvancedSearchCondition'
    description 'Sample Advanced Search Condition'

    argument :field, String, 'Field of advanced search condition', required: false
    argument :operator, SampleAdvancedSearchConditionOperatorInputType, 'Operator of advanced search condition',
             required: false
    argument :value, ValueScalar, 'Value of advanced search condition', required: false
  end
end
