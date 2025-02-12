# frozen_string_literal: true

# Validators
module Validators
  # Query Validator
  class QueryValidator < BaseValidator # rubocop:disable GraphQL/ObjectDescription
    def validate(_object, context, value)
      query = Sample::Query.new(params(value[:group_id], value[:filter], value[:order_by], context))

      return if query.valid?

      error_messages(query)
    end

    private

    def error_messages(query)
      errors = []
      query.groups.each do |group|
        group.conditions.each do |condition|
          condition.errors.messages.each do |attribute, message|
            errors << "'#{condition.send(attribute.to_sym)}' #{message.first}"
          end
        end
      end
      errors
    end

    def params(group_id, filter, order_by, context)
      filter = filter&.to_h
      params = {}
      params.merge!(filter_params(filter)) if filter
      params.merge!(sort: "#{order_by.field} #{order_by.direction}") if order_by.present?

      if group_id
        params.merge!(samples_by_group_scope(group_id:))
      else
        params.merge!(samples_by_project_scope(context))
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

    def samples_by_project_scope(context)
      scope = authorized_scope Project, type: :relation, context: { user: context[:current_user] }
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
