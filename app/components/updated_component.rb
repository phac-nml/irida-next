# frozen_string_literal: true

# A component for displaying when a record was updated.
class UpdatedComponent < ViewComponent::Base
  attr_reader :description, :updated_at

  def initialize(description:, updated_at:)
    @description = description
    @updated_at = updated_at
  end
end
