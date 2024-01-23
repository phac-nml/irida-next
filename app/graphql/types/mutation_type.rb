# frozen_string_literal: true

module Types
  # Mutation Type
  class MutationType < Types::BaseObject
    description 'The mutation root of this schema'

    field :create_sample, mutation: Mutations::CreateSample # rubocop:disable GraphQL/FieldDescription
    field :update_sample_metadata, mutation: Mutations::UpdateSampleMetadata # rubocop:disable GraphQL/FieldDescription
  end
end
