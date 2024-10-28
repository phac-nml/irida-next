# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class PipelinesResolver < BaseResolver
    type Types::PipelineType.connection_type, null: true

    # todo add argument to select type of pipelines

    def resolve
      Irida::Pipelines.instance.executable_pipelines.values
    end
  end
end
