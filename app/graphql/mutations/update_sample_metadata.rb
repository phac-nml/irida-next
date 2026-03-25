# frozen_string_literal: true

module Mutations
  # Mutation that updates sample metadata
  class UpdateSampleMetadata < BaseMutation # rubocop:disable Metrics/ClassLength
    description 'Update metadata for a sample.'

    argument :group_id, ID,
             required: false,
             description: 'The Node ID of the group to be updated. For example, `gid://irida/group/a84cd757-dedb-4c64-8b01-097020163077`' # rubocop:disable Layout/LineLength
    argument :group_puid, ID,
             required: false,
             description: 'Persistent Unique Identifier of the group. For example, `INXT_PRJ_AAAAAAAAAA`.'
    argument :metadata_payload, GraphQL::Types::JSON, required: true, # rubocop:disable GraphQL/ExtractInputType
                                                      description: 'The metadata to update the sample with.'
    argument :project_id, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'The Node ID of the project to be updated. For example, `gid://irida/project/a84cd757-dedb-4c64-8b01-097020163077`' # rubocop:disable Layout/LineLength
    argument :project_puid, ID, # rubocop:disable GraphQL/ExtractInputType
             required: false,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'
    validates required: { one_of: %i[project_id project_puid group_id group_puid] }

    field :errors, [Types::UserErrorType], description: 'A list of errors that prevented the mutation.'
    field :samples, [ID], description: 'List of updated sample ids.'
    field :status, GraphQL::Types::JSON, null: true, description: 'The status of the mutation.'

    def resolve(args) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      namespace = retrieve_namespace(args)

      if namespace.nil?
        path = args.key?(:project_puid) || args.key?(:project_id) ? 'project' : 'group'
        user_errors = [{
          path: [path],
          message: 'not found by provided ID or PUID'
        }]
        return {
          samples: nil,
          status: nil,
          errors: user_errors
        }
      end

      metadata_payload = args[:metadata_payload]
      # convert string to hash if json string as given
      metadata_payload = JSON.parse(metadata_payload) if metadata_payload.is_a?(String)

      unless metadata_payload.is_a?(Hash)
        user_errors = [{
          path: ['metadataPayload'],
          message: 'is not JSON data'
        }]
        return {
          samples: nil,
          status: nil,
          errors: user_errors
        }
      end

      payload_with_ids, metadata_fields, errors = build_metadata_fields_and_replace_gids(metadata_payload)

      unless errors.empty?
        user_errors = errors.map do |error|
          {
            path: ['metadata'],
            message: "#{error} metadata is not JSON data"
          }
        end
        return {
          samples: nil,
          status: nil,
          errors: user_errors
        }
      end

      Samples::Metadata::BulkUpdateService.new(namespace, payload_with_ids, metadata_fields, current_user).execute

      status = get_status_message(namespace, metadata_payload.keys.count)
      user_errors = namespace.errors.map do |error|
        {
          path: [error.attribute.to_s.camelize(:lower)],
          message: error.message
        }
      end
      {
        samples: nil,
        status:,
        errors: user_errors
      }
    rescue JSON::ParserError => e
      user_errors = [{
        path: ['metadata'],
        message: "JSON data is not formatted correctly. #{e.message}"
      }]
      {
        samples: nil,
        status: nil,
        errors: user_errors
      }
    end

    def ready?(**_args)
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      true
    end

    private

    def retrieve_namespace(args)
      if args.key?(:project_puid) || args.key?(:project_id)
        project = get_project_from_id_or_puid_args(args)
        project&.namespace
      else
        get_group_from_id_or_puid_args(args)
      end
    end

    def build_metadata_fields_and_replace_gids(metadata_payload) # rubocop:disable Metrics/MethodLength
      metadata_fields = []
      errors = []
      sample_gids_to_transform = {}
      metadata_payload.each do |sample_identifier, metadata|
        if sample_identifier.start_with?('gid://')
          sample_id = IridaSchema.parse_gid(sample_identifier, { expected_type: Sample }).model_id
          sample_gids_to_transform[sample_identifier] = sample_id
        end
        if metadata.is_a?(Hash)
          metadata_fields.concat(metadata.transform_keys(&:downcase).keys)
          metadata_fields.uniq
        else
          errors.append(sample_identifier)
        end
      end

      metadata_payload.transform_keys!(sample_gids_to_transform)
      [metadata_payload, metadata_fields, errors]
    end

    def get_status_message(namespace, sample_count)
      if namespace.errors.count == sample_count
        'unsuccessful'
      elsif namespace.errors.any?
        'successful with errors'
      else
        'successful with no errors'
      end
    end
  end
end
