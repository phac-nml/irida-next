# frozen_string_literal: true

# A component for displaying when a record was updated.
class UpdatedComponent < ViewComponent::Base
  attr_reader :updated_at

  def initialize(updated_at:)
    @updated_at = distance_of_time_in_words(Time.zone.now, updated_at, scope: 'datetime.distance_in_words.updated')
  end
end
