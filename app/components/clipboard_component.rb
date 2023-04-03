# frozen_string_literal: true

class ClipboardComponent < ViewComponent::Base
  def initialize(value:)
    @value = value
  end
end
