# frozen_string_literal: true

module Types
  # Mutation Type
  class MutationType < Types::BaseObject
    description 'The mutation root of this schema'

    field :attach_files_to_group, mutation: Mutations::AttachFilesToGroup # rubocop:disable GraphQL/FieldDescription
    field :attach_files_to_project, mutation: Mutations::AttachFilesToProject # rubocop:disable GraphQL/FieldDescription
    field :attach_files_to_sample, mutation: Mutations::AttachFilesToSample # rubocop:disable GraphQL/FieldDescription, GraphQL/ExtractType
    field :copy_samples, mutation: Mutations::CloneSamples # rubocop:disable GraphQL/FieldDescription
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload # rubocop:disable GraphQL/FieldDescription
    field :create_group, mutation: Mutations::CreateGroup # rubocop:disable GraphQL/FieldDescription
    field :create_project, mutation: Mutations::CreateProject # rubocop:disable GraphQL/FieldDescription
    field :create_sample, mutation: Mutations::CreateSample # rubocop:disable GraphQL/FieldDescription,GraphQL/ExtractType
    field :transfer_samples, mutation: Mutations::TransferSamples # rubocop:disable GraphQL/FieldDescription
    field :update_sample_metadata, mutation: Mutations::UpdateSampleMetadata # rubocop:disable GraphQL/FieldDescription
  end
end
