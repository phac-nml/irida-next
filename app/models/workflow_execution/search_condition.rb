# frozen_string_literal: true

# Model representing a single search condition in an advanced workflow execution query.
#
# Each condition defines a field, operator, and value for filtering workflow executions.
# Conditions are grouped together within SearchGroups, where multiple conditions within
# a group use AND logic, and multiple groups use OR logic.
#
# @example Creating a condition for completed workflows
#   condition = WorkflowExecution::SearchCondition.new(
#     field: 'state',
#     operator: '=',
#     value: 'completed'
#   )
#
# @example Creating a condition for metadata fields
#   condition = WorkflowExecution::SearchCondition.new(
#     field: 'workflow_name',
#     operator: 'contains',
#     value: 'iridanext'
#   )
class WorkflowExecution::SearchCondition # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :field
  attribute :operator
  attribute :value

  def empty?
    field.to_s.empty? && operator.to_s.empty? && value_empty?
  end

  private

  def value_empty?
    return value.compact.empty? if value.is_a?(Array)

    value.to_s.empty?
  end
end
