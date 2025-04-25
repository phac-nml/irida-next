# frozen_string_literal: true

# Represents a component for displaying a PUID (Persistent Unique Identifier)
class PuidComponent < ViewComponent::Base
  attr_reader :puid, :show_clipboard

  def initialize(puid:, show_clipboard: true)
    @puid = puid
    @show_clipboard = show_clipboard
  end
end
