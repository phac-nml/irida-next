# frozen_string_literal: true

# Model to represent workflow execution search group
# Used as part of advanced search functionality for filtering workflow executions
# Contains multiple search conditions that are combined with AND logic
# Multiple groups are combined with OR logic
class WorkflowExecution::SearchGroup # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  # References
  # https://coderwall.com/p/kvsbfa/nested-forms-with-activemodel-model-objects
  # https://jamescrisp.org/2020/10/12/rails-activemodel-with-nested-objects-and-validation/

  attribute :conditions, default: -> { [] }

  # Parses nested attributes from form submissions
  # Converts hash of condition parameters into SearchCondition objects
  # @param attributes [Hash] nested hash of condition attributes
  def conditions_attributes=(attributes)
    @conditions ||= []
    attributes.each_value do |condition_params|
      @conditions.push(WorkflowExecution::SearchCondition.new(condition_params))
    end
  end

  # Checks if all conditions in the group are empty
  # @return [Boolean] true if all conditions are empty
  def empty?
    conditions.all?(&:empty?)
  end
end
