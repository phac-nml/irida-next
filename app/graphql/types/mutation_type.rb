# frozen_string_literal: true

module Types
  # Mutation Type
  class MutationType < Types::BaseObject
    description 'The mutation root of this schema'

    field :attach_files_to_sample, mutation: Mutations::AttachFilesToSample # rubocop:disable GraphQL/FieldDescription
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload # rubocop:disable GraphQL/FieldDescription
    field :create_sample, mutation: Mutations::CreateSample # rubocop:disable GraphQL/FieldDescription,GraphQL/ExtractType
    field :update_sample_metadata, mutation: Mutations::UpdateSampleMetadata # rubocop:disable GraphQL/FieldDescription
  end
end
