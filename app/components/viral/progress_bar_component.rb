# frozen_string_literal: true

module Viral
  # Viral component for displaying a progress bar
  class ProgressBarComponent < Viral::Component
    attr_reader :text, :percentage

    def initialize(
      text: nil,
      percentage: 0,
      **system_arguments
    )
      @text = text
      @percentage = percentage
      @system_arguments = system_arguments
      @system_arguments[:classes] = class_names(
        'fixed bottom-4 right-4 z-50 w-64 p-4 bg-white rounded-lg shadow-md border border-gray-200',
        @system_arguments[:classes]
      )
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = 'progress-bar'
      @system_arguments[:data]['progress-bar-percentage-value'] = @percentage
    end
  end
end
