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

  class SampleAdvancedSearchConditionInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'SampleAdvancedSearchCondition'
    description 'Sample Advanced Search Condition'

    argument :field, String, 'Field of advanced search condition', required: false
    argument :operator, String, 'Operator of advanced search condition', required: false
    argument :value, String, 'Value of advanced search condition', required: false
  end

  class SampleAdvancedSearchConditionsInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'SampleAdvancedSearchConditions'
    description 'Sample Advanced Search Conditions'

    argument :advanced_search_conditions, [SampleAdvancedSearchConditionInputType],
             'A list of advanced search conditions',
             required: false, camelize: false,
             default_value: nil
  end
end
