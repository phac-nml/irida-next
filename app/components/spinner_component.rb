# frozen_string_literal: true

# Component for displaying spinner when loading
class SpinnerComponent < Component
  attr_reader :message

  def initialize(message:)
    @message = message
  end
end
