# frozen_string_literal: true

module Pathogen
  # Pathogen::Tooltip renders a tooltip that only appears on mouse hover or keyboard focus.
  class Tooltip < Pathogen::Component
    attr_reader :text, :id

    def initialize(text:, id:)
      @text = text
      @id = id
    end
  end
end
