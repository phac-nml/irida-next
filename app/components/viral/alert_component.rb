# frozen_string_literal: true

module Viral
  # View Component for alert messages (flash messages)
  # Enhanced with accessibility features, dismiss functionality, and modern design
  class AlertComponent < Viral::Component
    attr_reader :type, :message, :classes, :dismissible, :auto_dismiss

    TYPE_DEFAULT = :info
    TYPE_MAPPINGS = {
      alert: 'danger',
      notice: 'info',
      success: 'success',
      info: 'info',
      danger: 'danger',
      warning: 'warning'
    }.freeze

    def initialize(type: TYPE_DEFAULT, message: nil, dismissible: true, auto_dismiss: false, **system_arguments)
      @type = TYPE_MAPPINGS[type.to_sym] || TYPE_DEFAULT
      @message = message
      @dismissible = dismissible
      @auto_dismiss = auto_dismiss
      @system_arguments = system_arguments
      @system_arguments[:classes] =
        class_names('alert-component', classes_for_alert, @system_arguments[:classes])
      @system_arguments[:role] = 'alert'
      @system_arguments[:'aria-live'] = 'assertive'
      @system_arguments[:'aria-atomic'] = 'true'
    end

    def classes_for_alert
      case type
      when 'danger'
        'text-red-800 border-red-300 bg-red-50 dark:text-red-400 dark:bg-red-900/20 dark:border-red-800/50'
      when 'info'
        'text-blue-800 border-blue-300 bg-blue-50 dark:text-blue-400 dark:bg-blue-900/20 dark:border-blue-800/50'
      when 'success'
        'text-green-800 border-green-300 bg-green-50 dark:text-green-400 dark:bg-green-900/20 dark:border-green-800/50'
      when 'warning'
        'text-amber-800 border-amber-300 bg-amber-50 dark:text-amber-400 dark:bg-amber-900/20 dark:border-amber-800/50'
      else
        'text-slate-800 border-slate-300 bg-slate-50 dark:text-slate-400 dark:bg-slate-900/20 dark:border-slate-800/50'
      end
    end

    def icon_color
      case type
      when 'danger'
        :danger
      when 'info'
        :blue
      when 'success'
        :success
      when 'warning'
        :warning
      else
        :subdued
      end
    end

    def icon_name
      case type
      when 'danger'
        ICON::X_CIRCLE
      when 'info'
        ICON::INFO
      when 'success'
        ICON::CHECK_CIRCLE
      when 'warning'
        ICON::WARNING_CIRCLE
      else
        ICON::INFO
      end
    end

    def alert_id
      "alert-#{type}-#{object_id}"
    end

    def dismiss_button_id
      "#{alert_id}-dismiss"
    end

    def data_attributes
      {
        'data-controller': 'viral--alert',
        'data-viral--alert-dismissible-value': dismissible,
        'data-viral--alert-auto-dismiss-value': auto_dismiss,
        'data-viral--alert-type-value': type,
        'data-viral--alert-alert-id-value': alert_id,
        'data-viral--alert-dismiss-button-id-value': dismiss_button_id
      }
    end

    def system_arguments_with_data
      @system_arguments.merge(data_attributes)
    end
  end
end
