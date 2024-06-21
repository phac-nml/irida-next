# frozen_string_literal: true

module Viral
  # View Component for alert messages (flash messages)
  class AlertComponent < Viral::Component
    attr_reader :type, :message, :classes

    TYPE_DEFAULT = :info
    TYPE_MAPPINGS = {
      alert: 'danger',
      notice: 'info',
      success: 'success',
      info: 'info',
      danger: 'danger'
    }.freeze

    def initialize(type: TYPE_DEFAULT, message: nil, **system_arguments)
      @type = TYPE_MAPPINGS[type.to_sym] || TYPE_DEFAULT
      @message = message
      @system_arguments = system_arguments
      @system_arguments[:classes] =
        class_names('flex items-center p-4 border-l-4', classes_for_alert, @system_arguments[:classes])
      @system_arguments[:role] = 'alert'
    end

    def classes_for_alert
      case type
      when 'danger'
        'text-red-800 border-red-300 bg-red-50 dark:text-red-400 dark:bg-slate-800 dark:border-red-800'
      when 'info'
        'text-blue-800 border-blue-300 bg-blue-50 dark:text-blue-400 dark:bg-slate-800 dark:border-blue-800'
      when 'success'
        'text-green-800 border border-green-300 bg-green-50 dark:text-green-400 dark:bg-slate-800 dark:border-green-800'
      else
        'border-slate-300 bg-slate-50 dark:bg-slate-800 dark:border-slate-600'
      end
    end
  end
end
