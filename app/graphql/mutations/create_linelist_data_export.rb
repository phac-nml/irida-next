# frozen_string_literal: true

module Mutations
  # Mutation that creates a ready linelist data export from a direct-uploaded blob.
  class CreateLinelistDataExport < BaseMutation
    null true
    description 'Create a saved linelist data export from a direct-uploaded blob.'

    argument :linelist_format, String, required: true, description: 'Linelist export file format.'
    argument :metadata_fields, [String], required: false, description: 'Metadata fields included in the export.'
    argument :name, String, required: false, description: 'Data export name.' # rubocop:disable GraphQL/ExtractInputType
    argument :namespace_id, ID, required: true, description: 'Namespace the samples are exported from.' # rubocop:disable GraphQL/ExtractInputType
    argument :sample_ids, [ID], required: true, description: 'Sample IDs included in the export.' # rubocop:disable GraphQL/ExtractInputType
    argument :signed_blob_id, ID, required: true, description: 'Direct-uploaded Active Storage blob signed ID.' # rubocop:disable GraphQL/ExtractInputType

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :id, ID, null: true, description: 'Saved data export ID.', hash_key: :id # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :url, String, null: true, description: 'Saved data export show URL.'

    def resolve(args) # rubocop:disable Metrics/MethodLength
      data_export = DataExports::LinelistCreateService.new(
        current_user,
        service_params(args)
      ).execute

      if data_export.persisted?
        {
          id: data_export.id,
          url: Rails.application.routes.url_helpers.data_export_path(data_export),
          errors: []
        }
      else
        {
          id: nil,
          url: nil,
          errors: get_errors_from_object(data_export, 'dataExport')
        }
      end
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end

    private

    def service_params(args)
      {
        'name' => args[:name],
        'signed_blob_id' => args[:signed_blob_id],
        'namespace_id' => args[:namespace_id],
        'linelist_format' => args[:linelist_format],
        'sample_ids' => args[:sample_ids],
        'metadata_fields' => args[:metadata_fields] || []
      }
    end
  end
end
