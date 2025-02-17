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
    graphql_name 'SampleAdvancedSearchConditionOperator'
    description 'Sample Advanced Search Condition Operator'
    value 'EQUALS', value: '='
    value 'NOT_EQUALS', value: '!='
    value 'LESS_THAN_EQUALS', value: '<='
    value 'GREATER_THAN_EQUALS', value: '>='
    value 'CONTAINS', value: 'contains'
    value 'EXISTS', value: 'exists'
    value 'NOT_EXISTS', value: 'not_exists'
    value 'IN', value: 'in'
    value 'NOT_IN', value: 'not_in'
  end

  class ValueScalar < BaseScalar # rubocop:disable Style/Documentation
    description 'Sample Advanced Search Condition Value'

    def self.coerce_input(value, _context)
      return value if value.is_a?(String) || (value.is_a?(Array) && value.all? { |i| i.is_a?(String) })

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
