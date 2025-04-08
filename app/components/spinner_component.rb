# frozen_string_literal: true

# Component for displaying spinner when loading
class SpinnerComponent < Component
  attr_reader :message, :id

  def initialize(message:, id: nil)
    @message = message
    @id = id
  end
end
