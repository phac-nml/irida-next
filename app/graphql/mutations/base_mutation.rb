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
  end
end
