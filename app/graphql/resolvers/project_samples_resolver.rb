# frozen_string_literal: true

module Resolvers
  # Project Sample Resolver
  class ProjectSamplesResolver < BaseResolver
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

      filter = filter&.to_h
      search_params = {}
      search_params.merge!(advanced_search_params(filter)) if filter.present?
      search_params.merge!(sort: "#{order_by.field} #{order_by.direction}") if order_by.present?
      search_params.merge!({ project_ids: [project.id] })

      query = Sample::Query.new(search_params)
      query.results
    end

    private

    def advanced_search_params(filter)
      { groups_attributes: filter[:advanced_search_groups].map.with_index do |group, group_index|
        [group_index,
         { conditions_attributes: group.map.with_index do |condition, condition_index|
           [condition_index, condition]
         end.to_h }]
      end.to_h }
    end
  end
end
