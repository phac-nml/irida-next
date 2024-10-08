# frozen_string_literal: true

module Resolvers
  # Project Sample Resolver
  class ProjectSamplesResolver < BaseResolver
    alias project object

    argument :filter, Types::SampleFilterType,
             required: false,
             description: 'Ransack filter',
             default_value: nil

    argument :order_by, Types::SampleOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    def resolve(filter:, order_by:)
      context.scoped_set!(:project, project)
      context.scoped_set!(:samples_preauthorized, true)
      ransack_obj = project.samples.ransack(filter&.to_h)
      ransack_obj.sorts = ["#{order_by.field} #{order_by.direction}"] if order_by.present?

      ransack_obj.result
    end
  end
end
