# frozen_string_literal: true

module Resolvers
  # Project Sample Resolver
  class ProjectSamplesResolver < BaseResolver
    alias project object

    def resolve
      scope = project
      scope.samples
    end
  end
end
