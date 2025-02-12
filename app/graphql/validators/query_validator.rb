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
      query.groups.each do |group|
        group.conditions.each do |condition|
          condition.errors.messages.each do |attribute, message|
            errors << "'#{condition.send(attribute.to_sym)}' #{message.first}"
          end
        end
      end
      errors.uniq
    end
  end
end
