# frozen_string_literal: true

module Types
  # Sample Filter Type
  class SampleFilterType < BaseRansackFilterInputObject # rubocop:disable GraphQL/ObjectDescription
    argument :name_or_puid_cont, String, required: false, camelize: false,
                                         description: 'Filter samples which contains name or puid via Ransack'

    argument :name_or_puid_in, String, required: false, camelize: false,
                                       description: 'Filter samples by name or puid via Ransack'

    argument :advanced_search_groups, [SampleAdvancedSearchConditionsInputType],
             required: false, camelize: false,
             description: 'Filter samples by advanced search via Searchkick',
             default_value: nil
  end
end
