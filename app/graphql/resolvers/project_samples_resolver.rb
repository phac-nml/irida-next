# frozen_string_literal: true

module Resolvers
  # Project Sample Resolver
  class ProjectSamplesResolver < BaseResolver
    include QueryConcern

    alias project object

    argument :filter, Types::SampleFilterType,
             required: false,
             description: 'Sample filter',
             default_value: nil

    argument :order_by, Types::SampleOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    def resolve(filter:, order_by:)
      context.scoped_set!(:project, project)
      context.scoped_set!(:samples_preauthorized, true)

      query = Sample::Query.new(params(context, project.id, nil, filter, order_by))
      query.results
    end

    validates Validators::QueryValidator => {}
  end
end
