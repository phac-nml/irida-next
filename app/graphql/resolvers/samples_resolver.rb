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

    def resolve(group_id:, filter:)
      samples = group_id ? samples_by_group_scope(group_id:) : samples_by_project_scope
      filter ? samples.ransack(filter.to_h) : samples
    end

    def ready?(**_args)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
    end

    private

    def samples_by_project_scope
      scope = authorized_scope Project, type: :relation
      Sample.where(project_id: scope.select(:id))
    end

    def samples_by_group_scope(group_id:)
      group = IridaSchema.object_from_id(group_id, { expected_type: Group })
      authorize!(group, to: :sample_listing?, with: GroupPolicy)
      authorized_scope(Sample, type: :relation, as: :namespace_samples, scope_options: { namespace: group })
    end
  end
end
