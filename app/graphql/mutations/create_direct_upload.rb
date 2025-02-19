# frozen_string_literal: true

module Mutations
  # Mutation that Creates a blob to upload data to
  class CreateDirectUpload < BaseMutation
    description 'Create blob to upload data to.'

    argument :byte_size, Int, 'File size (bytes)', required: true,
                                                   validates: { numericality: { greater_than: 0 } }
    argument :checksum, String, 'MD5 file checksum as base64', required: true
    argument :content_type, String, 'File content type', required: true # rubocop:disable GraphQL/ExtractInputType
    argument :filename, String, 'Original file name', required: true # rubocop:disable GraphQL/ExtractInputType

    # Represents direct upload credentials
    class DirectUpload < GraphQL::Schema::Object
      description 'Represents direct upload credentials'

      field :blob_id, ID, 'Created blob record ID', null: false
      field :headers, String,
            'HTTP request headers (JSON-encoded)',
            null: false
      field :signed_blob_id, ID,
            'Created blob record signed ID',
            null: false
      field :url, String, 'Upload URL', null: false
    end

    field :direct_upload, DirectUpload, null: false, description: 'Represents direct upload credentials'

    def resolve(byte_size:, checksum:, content_type:, filename:)
      blob = ActiveStorage::Blob.create_before_direct_upload!(byte_size:, checksum:, content_type:, filename:)

      {
        direct_upload: {
          url: blob.service_url_for_direct_upload,
          # NOTE: we pass headers as JSON since they have no schema
          headers: blob.service_headers_for_direct_upload.to_json,
          blob_id: blob.id,
          signed_blob_id: blob.signed_id
        }
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end
  end
end
