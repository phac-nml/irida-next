# frozen_string_literal: true

# Model representing a group of search conditions in an advanced workflow execution query.
#
# A search group contains multiple conditions that are combined with AND logic.
# Multiple search groups are combined with OR logic, allowing for complex queries like:
# (state = completed AND workflow_name contains 'iridanext') OR (state = error)
#
# @example Creating a group with multiple conditions
#   group = WorkflowExecution::SearchGroup.new(
#     conditions: [
#       WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed'),
#       WorkflowExecution::SearchCondition.new(field: 'workflow_name', operator: 'contains', value: 'example')
#     ]
#   )
#
# @see WorkflowExecution::SearchCondition
# @see WorkflowExecution::Query
class WorkflowExecution::SearchGroup # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  # References
  # https://coderwall.com/p/kvsbfa/nested-forms-with-activemodel-model-objects
  # https://jamescrisp.org/2020/10/12/rails-activemodel-with-nested-objects-and-validation/

  attribute :conditions, default: -> { [] }

  def conditions_attributes=(attributes)
    @conditions ||= []
    attributes.each_value do |condition_params|
      @conditions.push(WorkflowExecution::SearchCondition.new(condition_params))
    end
  end

  def empty?
    conditions.all?(&:empty?)
  end
end
