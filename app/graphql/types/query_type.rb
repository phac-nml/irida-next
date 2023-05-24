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

    def current_user
      context[:current_user]
    end
  end
end
