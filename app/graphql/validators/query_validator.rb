# frozen_string_literal: true

module Validators
  # Query Validator
  class QueryValidator < BaseValidator # rubocop:disable GraphQL/ObjectDescription
    include QueryConcern

    def validate(_object, context, value)
      query = Sample::Query.new(params(context, value[:project_id], value[:group_id], value[:filter], value[:order_by]))

      return if query.valid?

      error_messages(query:)
    end

    private

    def error_messages(query:)
      errors = []
      query.groups.each_with_index do |group, group_index|
        group.conditions.each_with_index do |condition, condition_index|
          condition.errors.messages.each do |attribute, message|
            errors << "#{error_message_prefix(group_index, condition_index,
                                              attribute)} '#{condition.send(attribute.to_sym)}' #{message.first}"
          end
        end
      end
      errors.uniq
    end

    def error_message_prefix(group_index, condition_index, attribute)
      "filter.advanced_search_groups.#{group_index}.#{condition_index}.#{attribute.to_s.camelize(:lower)}:"
    end
  end
end
