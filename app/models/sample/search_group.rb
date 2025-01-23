# frozen_string_literal: true

# model to represent sample search group
class Sample::SearchGroup # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  # References
  # https://coderwall.com/p/kvsbfa/nested-forms-with-activemodel-model-objects
  # https://jamescrisp.org/2020/10/12/rails-activemodel-with-nested-objects-and-validation/

  attribute :conditions, default: -> { [] }

  def conditions_attributes=(attributes)
    @conditions ||= []
    attributes.each_value do |condition_params|
      @conditions.push(Sample::SearchCondition.new(condition_params))
    end
  end

  def empty?
    conditions.all?(&:empty?)
  end
end
