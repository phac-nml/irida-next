# frozen_string_literal: true

# Represents a component for displaying a PUID (Persistent Unique Identifier)
class PuidComponent < ViewComponent::Base
  attr_reader :puid

  def initialize(puid:)
    @puid = puid
  end
end
