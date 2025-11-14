# frozen_string_literal: true

# model to represent sample search condition
class Sample::SearchCondition # rubocop:disable Style/ClassAndModuleChildren
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
