# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell
  class EditableCell < Component
    with_collection_parameter :field

    def initialize(field:, sample:, autofocus: false)
      @sample = sample
      @field = field
      @autofocus = autofocus
    end
  end
end
