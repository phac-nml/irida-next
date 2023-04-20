# frozen_string_literal: true

module Viral
  # View Component for UI flash messages
  class FlashComponent < Component
    attr_reader :type, :data, :timeout, :icon, :classes

    DEFAULT_TIMEOUT = 3500

    def initialize(type:, data:, timeout: DEFAULT_TIMEOUT)
      @type = type
      @data = data
      @timeout = timeout
      @icon = icon_for_flash
      @classes = classes_for_flash
    end

    def classes_for_flash
      case type
      when 'error'
        'bg-red-600 dark:bg-red-800'
      when 'success'
        'bg-green-700 dark:bg-green-900'
      when 'warning'
        'bg-yellow-600 dark:bg-yellow-900'
      else
        'bg-blue-600 dark:bg-blue-800'
      end
    end

    def icon_for_flash
      case type
      when 'error'
        'exclamation_circle'
      when 'success'
        'check'
      when 'warning'
        'exclamation_triangle'
      else
        'information_circle'
      end
    end
  end
end
