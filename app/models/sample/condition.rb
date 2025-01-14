# frozen_string_literal: true

# model to represent sample search condition
class Sample::Condition # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :field, :string
  attribute :operator, :string
  attribute :value

  validates :operator, inclusion: { in: %w[= != <= >= contains in not_in] }

  def empty?
    field.empty? && operator.empty? && ((value.is_a?(Array) && value.compact!.nil?) || value.empty?)
  end
end
