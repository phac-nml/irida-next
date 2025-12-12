# frozen_string_literal: true

# Model to represent workflow execution search condition
# Used as part of advanced search functionality for filtering workflow executions
# Stores a single search criterion with field, operator, and value
class WorkflowExecution::SearchCondition # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :field
  attribute :operator
  attribute :value

  # Checks if the search condition is empty
  # @return [Boolean] true if all attributes are blank or empty
  def empty?
    field.empty? && operator.empty? && ((value.is_a?(Array) && value.compact!.nil?) || value.empty?)
  end
end
