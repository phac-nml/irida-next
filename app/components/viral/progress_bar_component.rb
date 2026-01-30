# frozen_string_literal: true

module Viral
  # Viral component for displaying a progress bar
  class ProgressBarComponent < Viral::Component
    attr_reader :text

    def initialize(
      text: nil,
      **system_arguments
    )
      @text = text
      @system_arguments = system_arguments
      @system_arguments[:classes] = class_names(
        'fixed bottom-4 right-4 z-50 w-64 p-4 bg-white rounded-lg shadow-md border border-gray-200',
        @system_arguments[:classes]
      )
    end
  end
end
