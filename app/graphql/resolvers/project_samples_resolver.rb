# frozen_string_literal: true

module Resolvers
  # Project Sample Resolver
  class ProjectSamplesResolver < BaseResolver
    alias project object

    argument :filter, Types::SampleFilterType,
             required: false,
             description: 'Ransack & Searchkick filter',
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
      search_params.merge!(filter_params(filter)) if filter
      search_params.merge!(sort: "#{order_by.field} #{order_by.direction}") if order_by.present?
      search_params.merge!({ project_ids: [project.id] })

      query = Sample::Query.new(search_params)
      query.results
    end

    private

    def filter_params(filter)
      filter_params = {}
      filter_params.merge!(advanced_search_params(filter)) if filter[:advanced_search_groups]
      filter_params.merge!(name_or_puid_cont: filter[:name_or_puid_cont]) if filter[:name_or_puid_cont]
      filter_params.merge!(name_or_puid_in: filter[:name_or_puid_in]) if filter[:name_or_puid_in]
      filter_params
    end

    def advanced_search_params(filter)
      groups = {}
      filter[:advanced_search_groups].each_with_index do |group, group_index|
        conditions = {}
        group[:advanced_search_conditions].each_with_index do |condition, condition_index|
          conditions.merge!({ condition_index => condition })
        end
        groups.merge!({ group_index => { conditions_attributes: conditions } })
      end
      { groups_attributes: groups }
    end
  end
end
