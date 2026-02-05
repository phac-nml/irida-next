# frozen_string_literal: true

module Viral
  # Viral component for displaying a progress bar
  class ProgressBarComponent < Viral::Component
    attr_reader :text, :percentage, :open

    def initialize(
      text: nil,
      percentage: 0,
      open: false,
      **system_arguments
    )
      @text = text
      @percentage = percentage
      @open = open
      @system_arguments = system_arguments
      @system_arguments[:id] = 'test-me'
      @system_arguments[:classes] = class_names(
        'fixed bottom-4 right-4 z-50 w-64 p-4 bg-white rounded-lg shadow-md border border-gray-200',
        @system_arguments[:classes]
      )
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = 'viral--progress-bar'
      @system_arguments[:data]['viral--progress-bar-percentage-value'] = @percentage
      @system_arguments[:data]['viral--progress-bar-open-value'] = @open
    end
  end
end
