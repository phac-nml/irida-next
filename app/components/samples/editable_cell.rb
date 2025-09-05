# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell
  class EditableCell < Component
    def initialize(field:, sample:, autofocus: false, **system_arguments)
      @sample = sample
      @field = field
      @autofocus = autofocus
      @system_arguments = system_arguments
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:'editable-cell-target'] = 'editableCell'
    end
  end
end
