# frozen_string_literal: true

module Types
  # Sample Filter Type
  class SampleFilterType < BaseRansackFilterInputObject # rubocop:disable GraphQL/ObjectDescription
    argument :name_or_puid_cont, String, required: false, camelize: false,
                                         description: 'Filter samples which contains name or puid'

    argument :advanced_search, [[SampleAdvancedSearchConditionInputType]],
             required: false, camelize: false,
             description: 'Filter samples by advanced search',
             default_value: nil
  end
end
