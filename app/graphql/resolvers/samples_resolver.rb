# frozen_string_literal: true

module Resolvers
  # Samples Resolver
  class SamplesResolver < BaseResolver
    type Types::SampleType.connection_type, null: true

    argument :group_id, GraphQL::Types::ID,
             required: false,
             description: 'Optional group identifier to return list of samples for.',
             default_value: nil

    argument :filter, Types::SampleFilterType,
             required: false,
             description: 'Sample filter',
             default_value: nil

    argument :order_by, Types::SampleOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    def resolve(group_id:, filter:, order_by:)
      context.scoped_set!(:samples_preauthorized, true)

      filter = filter&.to_h
      search_params = {}
      search_params.merge!(advanced_search_params(filter)) if filter.present?
      search_params.merge!(sort: "#{order_by.field} #{order_by.direction}") if order_by.present?

      if group_id
        search_params.merge!(samples_by_group_scope(group_id:))
      else
        search_params.merge!(samples_by_project_scope)
      end

      query = Sample::Query.new(search_params)
      query.results
    end

    def ready?(**_args)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
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

    def samples_by_project_scope
      scope = authorized_scope Project, type: :relation
      { project_ids: scope.pluck(:id) }
    end

    def samples_by_group_scope(group_id:)
      group = IridaSchema.object_from_id(group_id, { expected_type: Group })
      authorize!(group, to: :sample_listing?, with: GroupPolicy, context: { token: context[:token] })
      # authorized_scope(Sample, type: :relation, as: :namespace_samples, scope_options: { namespace: group })
      project_ids =
        authorized_scope(Project, type: :relation, as: :group_projects, scope_options: { group: group }).pluck(:id)
      { project_ids: project_ids }
    end
  end
end
