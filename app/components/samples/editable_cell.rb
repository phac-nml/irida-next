# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell
  class EditableCell < Component
    def initialize(field:, sample:, autofocus: false)
      @sample = sample
      @field = field
      @autofocus = autofocus
    end
  end
end
