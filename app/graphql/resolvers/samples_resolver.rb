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

      query = Sample::Query.new(params(group_id, filter, order_by))
      if query.valid?
        query.results
      else
        handle_validation_errors(query)
      end
    end

    def ready?(**_args)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
    end

    private

    def handle_validation_errors(query)
      errors = []
      query.groups.each do |group|
        group.conditions.each do |condition|
          condition.errors.messages.each do |attribute, message|
            errors << "'#{condition.send(attribute.to_sym)}' #{message.first}"
          end
        end
      end

      raise GraphQL::ExecutionError.new(
        'Validation failed',
        extensions: {
          validationErrors: errors
        }
      )
    end

    def params(group_id, filter, order_by)
      filter = filter&.to_h
      params = {}
      params.merge!(filter_params(filter)) if filter
      params.merge!(sort: "#{order_by.field} #{order_by.direction}") if order_by.present?

      if group_id
        params.merge!(samples_by_group_scope(group_id:))
      else
        params.merge!(samples_by_project_scope)
      end
    end

    def filter_params(filter)
      filter_params = {}
      filter_params.merge!(advanced_search_params(filter)) if filter[:advanced_search_groups]
      filter_params.merge!(name_or_puid_cont: filter[:name_or_puid_cont]) if filter[:name_or_puid_cont]
      filter_params
    end

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
