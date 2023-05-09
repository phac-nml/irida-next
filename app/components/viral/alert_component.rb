# frozen_string_literal: true

module Viral
  # View Component for alert messages (flash messages)
  class AlertComponent < Component
    attr_reader :type, :message, :classes

    def initialize(type: 'info', message: nil)
      @type = type
      @message = message
      @classes = classes_for_alert
    end

    def classes_for_alert
      case type
      when 'alert'
        'text-red-800 border-red-300 bg-red-50 dark:text-red-400 dark:bg-gray-800 dark:border-red-800'
      when 'notice'
        'text-blue-800 border-blue-300 bg-blue-50 dark:text-blue-400 dark:bg-gray-800 dark:border-blue-800'
      else
        'border-gray-300 bg-gray-50 dark:bg-gray-800 dark:border-gray-600'
      end
    end
  end
end
