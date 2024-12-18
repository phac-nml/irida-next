# frozen_string_literal: true

# model to represent sample search condition
class Condition
  include ActiveModel::Model
  include ActiveModel::Attributes

  # attr_accessor :field, :operator, :value

  attribute :field, :string
  attribute :operator, :string
  attribute :value, :string

  validates :operator, inclusion: { in: %w[= != <= >= < > contains] }
end
