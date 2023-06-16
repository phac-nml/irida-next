# frozen_string_literal: true

# Confirmation dialog component
class ConfirmationComponent < Component
  attr_reader :value, :title

  renders_one :message

  def initialize(value:, title:)
    @value = value
    @title = title
  end
end
