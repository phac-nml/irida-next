# frozen_string_literal: true

module Resolvers
  # Projects Resolver
  class ProjectsResolver < BaseResolver
    type Types::ProjectType.connection_type, null: true

    def resolve
      authorized_scope Project, type: :relation
    end
  end
end
