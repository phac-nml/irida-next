# frozen_string_literal: true

module Resolvers
  # Samples Resolver
  class SamplesResolver < BaseResolver
    type Types::SampleType.connection_type, null: true

    def resolve
      scope = authorized_scope Project, type: :relation
      Sample.where(project_id: scope.select(:id))
    end
  end
end
