# frozen_string_literal: true

module Types
  class SampleOrderFieldInputType < BaseEnum # rubocop:disable Style/Documentation
    graphql_name 'SampleOrderField'
    description 'Field to sort the samples by'
    value 'created_at'
    value 'updated_at'
    value 'name'
  end

  class SampleOrderInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'SampleOrder'
    description 'Specify a sort for the samples'

    argument :direction, OrderDirectionType, required: false # rubocop:disable GraphQL/ArgumentDescription
    argument :field, SampleOrderFieldInputType, required: true # rubocop:disable GraphQL/ArgumentDescription
  end
end
