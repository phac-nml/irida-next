# frozen_string_literal: true

# model to represent workflow execution search group
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
