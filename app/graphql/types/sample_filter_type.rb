# frozen_string_literal: true

module Types
  # Sample Filter Type
  class SampleFilterType < BaseRansackFilterInputObject # rubocop:disable GraphQL/ObjectDescription
    argument :advanced_search_groups, [SampleAdvancedSearchConditionsInputType],
             required: false, camelize: false,
             description: 'Filter samples by advanced search via Searchkick',
             default_value: nil
  end
end
