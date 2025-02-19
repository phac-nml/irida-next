# frozen_string_literal: true

module Types
  class GroupOrderFieldInputType < BaseEnum # rubocop:disable Style/Documentation
    graphql_name 'GroupOrderField'
    description 'Field to sort the groups by'
    value 'created_at'
    value 'updated_at'
    value 'name', value_method: :group_name
  end

  class GroupOrderInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'GroupOrder'
    description 'Specify a sort for the groups'

    argument :direction, OrderDirectionType, required: false # rubocop:disable GraphQL/ArgumentDescription
    argument :field, GroupOrderFieldInputType, required: true # rubocop:disable GraphQL/ArgumentDescription
  end
end
