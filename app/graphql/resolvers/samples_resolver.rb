# frozen_string_literal: true

module Resolvers
  # Samples Resolver
  class SamplesResolver < BaseResolver
    type Types::SampleType.connection_type, null: true

    argument :group_id, GraphQL::Types::ID,
             required: false,
             description: 'Optional group identifier to return list of samples for.',
             default_value: nil

    def resolve(group_id:)
      if group_id
        @group = Group.find_by_full_path(group_id) # rubocop:disable Rails/DynamicFindBy
        authorized_scope(Sample, type: :relation, as: :group_samples, scope_options: { group: @group })
      else
        scope = authorized_scope Project, type: :relation
        Sample.where(project_id: scope.select(:id))
      end
    end
  end
end
