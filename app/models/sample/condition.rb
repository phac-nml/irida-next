# frozen_string_literal: true

# model to represent sample search condition
class Sample::Condition # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :field, :string
  attribute :operator, :string
  attribute :value, :string

  validates :operator, inclusion: { in: %w[= != <= >= between contains] }
end
