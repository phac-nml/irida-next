# frozen_string_literal: true

module Types
  # Query Type
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    description 'The query root of this schema'

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :current_user, Types::UserType, null: true, description: 'Get information about current user.'

    field :group, Types::GroupType, null: true, authorize: { to: :read? }, resolver: Resolvers::GroupResolver,
                                    description: 'Find a group.'
    field :groups, Types::GroupType.connection_type, null: false, resolver: Resolvers::GroupsResolver,
                                                     description: 'Find groups.'

    field :namespace, Types::NamespaceType, null: true, authorize: { to: :read? },
                                            resolver: Resolvers::NamespaceResolver,
                                            description: 'Find a namespace.'

    field :project, Types::ProjectType, null: true, authorize: { to: :read? }, resolver: Resolvers::ProjectResolver,
                                        description: 'Find a project.'

    field :projects, Types::ProjectType.connection_type, null: true, resolver: Resolvers::ProjectsResolver,
                                                         description: 'Find projects.'

    field :sample, Types::SampleType, null: true, resolver: Resolvers::SampleResolver,
                                      description: 'Find a sample.'

    field :samples, Types::SampleType.connection_type, null: true, resolver: Resolvers::SamplesResolver,
                                                       description: 'Find samples.'

    def current_user
      context[:current_user]
    end
  end
end
