# frozen_string_literal: true

module Types
  class AttachmentOrderFieldInputType < BaseEnum # rubocop:disable Style/Documentation
    graphql_name 'AttachmentOrderField'
    description 'Field to sort the attachments by'
    value 'created_at'
    value 'updated_at'
    value 'filename'
  end

  class AttachmentOrderInputType < BaseInputObject # rubocop:disable Style/Documentation
    graphql_name 'AttachmentOrder'
    description 'Specify a sort for the attachments'

    argument :direction, OrderDirectionType, required: false # rubocop:disable GraphQL/ArgumentDescription
    argument :field, AttachmentOrderFieldInputType, required: true # rubocop:disable GraphQL/ArgumentDescription
  end
end
