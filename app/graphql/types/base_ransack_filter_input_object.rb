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
    base_description = 'Sample Advanced Search Condition Operator'
    if Flipper.enabled?(:advanced_search_metadata_operators)
      base_description += "\n- To search metadata fields, use the operators below starting with 'METADATA_*'\n- For all other fields, use the operators that are not prefixed with 'METADATA_*'" # rubocop:disable Layout/LineLength
    end
    graphql_name 'SampleAdvancedSearchConditionOperator'
    description base_description

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
    value 'METADATA_DATE_GREATER_THAN_EQUALS', value: 'date_greater_than_equals'
    value 'METADATA_DATE_LESS_THAN_EQUALS', value: 'date_less_than_equals'
    value 'METADATA_DATE_EQUALS', value: 'date_equals'
    value 'METADATA_DATE_NOT_EQUALS', value: 'date_not_equals'
    value 'METADATA_NUMERIC_GREATER_THAN_EQUALS', value: 'numeric_greater_than_equals'
    value 'METADATA_NUMERIC_LESS_THAN_EQUALS', value: 'numeric_less_than_equals'
    value 'METADATA_NUMERIC_EQUALS', value: 'numeric_equals'
    value 'METADATA_NUMERIC_NOT_EQUALS', value: 'numeric_not_equals'
    value 'METADATA_TEXT_EQUALS', value: 'text_equals'
    value 'METADATA_TEXT_NOT_EQUALS', value: 'text_not_equals'
    value 'METADATA_TEXT_IN', value: 'text_in'
    value 'METADATA_TEXT_NOT_IN', value: 'text_not_in'
    value 'METADATA_TEXT_CONTAINS', value: 'text_contains'
    value 'METADATA_TEXT_NOT_CONTAINS', value: 'text_not_contains'
    value 'METADATA_EXISTS', value: 'exists'
    value 'METADATA_NOT_EXISTS', value: 'not_exists'

    # only enable metadata operators with enabled feature flag
    def self.enum_values(context)
      all_values = super

      if Flipper.enabled?(:advanced_search_metadata_operators)
        all_values
      else
        all_values.reject { |value_obj| value_obj.graphql_name.starts_with?('METADATA_') }
      end
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
