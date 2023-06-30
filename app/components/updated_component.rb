# frozen_string_literal: true

# A component for displaying when a record was updated.
class UpdatedComponent < ViewComponent::Base
  attr_reader :description, :updated_at

  def initialize(updated_at:, description: I18n.t(:'time.updated'))
    @description = description
    @updated_at = distance_of_time_in_words(Time.zone.now, updated_at)
  end
end
