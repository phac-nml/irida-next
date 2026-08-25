# frozen_string_literal: true

module Types
  # Mutation Type
  class MutationType < Types::BaseObject
    description 'The mutation root of this schema'

    field :attach_files_to_group, mutation: Mutations::AttachFilesToGroup
    field :attach_files_to_project, mutation: Mutations::AttachFilesToProject
    field :attach_files_to_sample, mutation: Mutations::AttachFilesToSample # rubocop:disable GraphQL/ExtractType
    field :bulk_update_sample_metadata, mutation: Mutations::BulkUpdateSampleMetadata
    field :copy_samples, mutation: Mutations::CloneSamples
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload
    field :create_group, mutation: Mutations::CreateGroup
    field :create_project, mutation: Mutations::CreateProject
    field :create_sample, mutation: Mutations::CreateSample # rubocop:disable GraphQL/ExtractType
    field :submit_workflow_execution, mutation: Mutations::SubmitWorkflowExecution
    field :transfer_samples, mutation: Mutations::TransferSamples
    field :update_sample_metadata, mutation: Mutations::UpdateSampleMetadata
  end
end
