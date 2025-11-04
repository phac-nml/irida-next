# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class PipelinesResolver < BaseResolver
    argument :workflow_type, String,
             required: false,
             default_value: 'executable',
             description: 'Can specify `automatable` for automatable pipelines, or `available` for all pipelines. By default only `executable` pipelines are returned.' # rubocop:disable Layout/LineLength

    def resolve(workflow_type:)
      case workflow_type
      when 'executable'
        Irida::Pipelines.instance.pipelines('executable').values
      when 'automatable'
        Irida::Pipelines.instance.pipelines('automatable').values
      when 'available'
        Irida::Pipelines.instance.pipelines.values
      end
    end
  end
end
