# frozen_string_literal: true

module Types
  class ProjectOrderFieldInputType < BaseEnum # rubocop:disable Style/Documentation
    graphql_name 'ProjectOrderField'
    description 'Field to sort the samples by'
    value 'created_at'
    value 'updated_at'
    value 'name'
  end

  class ProjectOrderInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'ProjectOrder'
    description 'Specify a sort for the projects'

    argument :direction, OrderDirectionType, required: false # rubocop:disable GraphQL/ArgumentDescription
    argument :field, ProjectOrderFieldInputType, required: true # rubocop:disable GraphQL/ArgumentDescription
  end
end
