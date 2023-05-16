# frozen_string_literal: true

module Resolvers
  # Groups Resolver
  class GroupsResolver < BaseResolver
    type Types::GroupType.connection_type, null: true

    def resolve
      authorized_scope Group, type: :relation
    end
  end
end
