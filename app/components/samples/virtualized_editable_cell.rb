# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell in virtualized table
  class VirtualizedEditableCell < Component
    def initialize(field:, sample:, autofocus: false, **system_arguments)
      @sample = sample
      @field = field
      @autofocus = autofocus
      @system_arguments = system_arguments
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:'editable-cell-target'] = 'editableCell'
      @system_arguments[:data][:'field-id'] = field # Add field-id for editable_cell_controller
      @system_arguments[:role] ||= 'gridcell'
    end
  end
end
