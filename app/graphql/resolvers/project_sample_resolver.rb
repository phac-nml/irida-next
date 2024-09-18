# frozen_string_literal: true

module Resolvers
  # Project Sample Resolver
  class ProjectSampleResolver < BaseResolver
    argument :project_puid, GraphQL::Types::ID,
             required: true,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'
    argument :sample_name, GraphQL::Types::String,
             required: false,
             description: 'Name of the sample.'
    argument :sample_puid, GraphQL::Types::ID,
             required: false,
             description: 'Persistent Unique Identifier of the sample. For example, `INXT_SAM_AAAAAAAAAA`.'
    validates required: { one_of: %i[sample_name sample_puid] }

    type Types::SampleType, null: true

    def resolve(args)
      project = Namespaces::ProjectNamespace.find_by(puid: args[:project_puid])&.project
      context.scoped_set!(:project, project)
      if args[:sample_puid]
        Sample.find_by(puid: args[:sample_puid], project:)
      else
        Sample.find_by(name: args[:sample_name], project:)
      end
    end
  end
end
