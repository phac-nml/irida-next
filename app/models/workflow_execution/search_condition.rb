# frozen_string_literal: true

# model to represent workflow execution search condition
class WorkflowExecution::SearchCondition # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :field
  attribute :operator
  attribute :value

  def empty?
    field.empty? && operator.empty? && ((value.is_a?(Array) && value.compact!.nil?) || value.empty?)
  end
end
