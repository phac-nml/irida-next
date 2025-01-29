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
             description: 'Ransack filter',
             default_value: nil

    argument :order_by, Types::SampleOrderInputType,
             required: false,
             description: 'Order by',
             default_value: nil

    def resolve(group_id:, filter:, order_by:)
      context.scoped_set!(:samples_preauthorized, true)

      search_params = advanced_search_params(filter)
      search_params.merge!(sort: "#{order_by.field} #{order_by.direction}") if order_by.present?

      if group_id
        search_params.merge!(samples_by_group_scope(group_id:))
      else
        search_params.merge!(samples_by_project_scope)
      end

      # search_params.merge!({ project_ids: ['0129a30d-97ed-4a7f-a84a-33efeca83b0a'] }).to_json

      query = Sample::Query.new(search_params)
      samples = query.results

      Sample.where(id: samples.pluck(:id)) # TODO
    end

    def ready?(**_args)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
    end

    private

    def advanced_search_params(filter)
      groups = {}
      filter[:search_groups].each_with_index do |group, group_index|
        conditions = {}
        group[:search_conditions].each_with_index do |condition, condition_index|
          conditions.merge!({ condition_index => condition.to_h })
        end
        groups.merge!({ group_index => { conditions_attributes: conditions } })
      end
      { groups_attributes: groups }
    end

    def samples_by_project_scope
      scope = authorized_scope Project, type: :relation
      { project_ids: [scope.select(:id)] }
    end

    def samples_by_group_scope(group_id:)
      group = IridaSchema.object_from_id(group_id, { expected_type: Group })
      # authorize!(group, to: :sample_listing?, with: GroupPolicy, context: { token: context[:token] })
      # authorized_scope(Sample, type: :relation, as: :namespace_samples, scope_options: { namespace: group })
      project_ids =
        authorized_scope(Project, type: :relation, as: :group_projects, scope_options: { group: group }).pluck(:id)
      { project_ids: project_ids }
    end
  end
end
