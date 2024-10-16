# frozen_string_literal: true

module Mutations
  # Base Mutation
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include ActionPolicy::GraphQL::Behaviour

    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    protected

    SAMPLE_ID_PREFIX = 'gid://irida/Sample/'

    def get_sample_from_id_or_puid_args(args)
      if args[:sample_id]
        IridaSchema.object_from_id(args[:sample_id], { expected_type: Sample })
      else
        Sample.find_by!(puid: args[:sample_puid])
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def get_project_from_id_or_puid_args(args)
      if args[:project_id]
        IridaSchema.object_from_id(args[:project_id], { expected_type: Project })
      else
        project_namespace = Namespaces::ProjectNamespace.find_by!(puid: args[:project_puid])
        project_namespace&.project
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def get_group_from_id_or_puid_args(args)
      if args[:group_id]
        IridaSchema.object_from_id(args[:group_id], { expected_type: Group })
      else
        Group.find_by!(puid: args[:group_puid])
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def attachment_status_and_errors(files_attached:, file_blob_id_list:)
      # initialize status hash such that all blob ids given by user are included
      status = Hash[*file_blob_id_list.collect { |v| [v, nil] }.flatten]
      user_errors = []

      files_attached.each do |attachment|
        id = attachment.file.blob.signed_id
        if attachment.persisted?
          status[id] = :success
        else
          status[id] = :error
          attachment.errors.each do |error|
            user_errors.append({ path: ['attachment', id], message: error.message })
          end
        end
      end

      add_missing_blob_id_error(status:, user_errors:)
    end

    def add_missing_blob_id_error(status:, user_errors:)
      # any nil status is an error
      status.each do |id, value|
        next unless value.nil?

        status[id] = :error
        user_errors.append({ path: ['blob_id', id],
                             message: 'Blob id could not be processed. Blob id is invalid or file is missing.' })
      end

      [status, user_errors]
    end

    def get_errors_from_object(object, base_path)
      object.errors.map do |error|
        {
          path: [base_path, error.attribute.to_s.camelize(:lower)],
          message: error.message
        }
      end
    end
  end
end
