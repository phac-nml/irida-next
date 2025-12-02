# frozen_string_literal: true

module Viral
  # ViewComponent for accessible alert/flash messages.
  #
  # Responsibilities
  # - Render a contextual alert with consistent, theme-aware styles
  # - Provide accessible semantics (role, aria-live, aria-atomic)
  # - Support optional dismiss button and optional auto-dismiss progress bar
  # - Expose a stable set of data attributes for the Stimulus controller "viral--alert"
  #
  # Usage
  #   render Viral::AlertComponent.new(
  #     type: :success, message: t('notices.saved'), dismissible: true
  #   )
  #   # or with a block for additional content
  #   render(Viral::AlertComponent.new(type: :warning)) { content_tag(:p, 'Heads up') }
  #
  # Notes
  # - The `type` argument accepts Rails-style flash keys (:notice, :alert) as aliases.
  # - Helper methods used by the template are private to keep the public API small.
  class AlertComponent < Viral::Component
    # Public, read-only inputs surfaced to the template
    # @return [Symbol] one of :danger, :info, :success, :warning
    attr_reader :type
    # @return [String, nil]
    attr_reader :message
    # @return [Boolean]
    attr_reader :dismissible, :auto_dismiss

    # Default logical type
    TYPE_DEFAULT = :info
    # Maps incoming logical types (including Rails flash keys) to canonical UI states
    TYPE_MAPPINGS = {
      alert: :danger,
      notice: :info,
      success: :success,
      info: :info,
      danger: :danger,
      warning: :warning
    }.freeze
    # Canonical, rendered types
    TYPE_OPTIONS = TYPE_MAPPINGS.values.uniq.freeze

    # Initialize the Alert component.
    #
    # @param type [Symbol, String] logical type or Rails flash key; mapped to {TYPE_OPTIONS}
    # @param message [String, nil] optional short message; block content renders as body
    # @param dismissible [Boolean] whether to render a close button
    # @param auto_dismiss [Boolean] whether to render a progress bar that a Stimulus controller can manage
    # @param system_arguments [Hash] additional HTML attributes (classes are merged)
    def initialize(type: TYPE_DEFAULT, message: nil, dismissible: true, auto_dismiss: false, **system_arguments)
      # Normalize to canonical string type for styling and iconography
      @type = TYPE_MAPPINGS[type.to_sym] || TYPE_MAPPINGS[TYPE_DEFAULT]
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

    # Compose safe HTML attributes for the outer wrapper, including Stimulus data attributes.
    #
    # @return [Hash] merged attributes suitable for tag helpers
    def system_arguments_with_data
      @system_arguments.merge(data_attributes)
    end

    private

    # Tailwind utility classes for the current alert type.
    # @return [String]
    def classes_for_alert
      case type
      when :danger
        'text-red-800 border-red-300 bg-red-50 dark:text-red-400 dark:bg-red-900/20 dark:border-red-800/50'
      when :info
        'text-blue-800 border-blue-300 bg-blue-50 dark:text-blue-400 dark:bg-blue-900/20 dark:border-blue-800/50'
      when :success
        'text-green-800 border-green-300 bg-green-50 dark:text-green-400 dark:bg-green-900/20 dark:border-green-800/50'
      when :warning
        'text-amber-800 border-amber-300 bg-amber-50 dark:text-amber-400 dark:bg-amber-900/20 dark:border-amber-800/50'
      else
        'text-slate-800 border-slate-300 bg-slate-50 dark:text-slate-400 dark:bg-slate-900/20 dark:border-slate-800/50'
      end
    end

    # Icon color token for the current alert type.
    # @return [Symbol]
    def icon_color
      case type
      when :danger then :danger
      when :info then :blue
      when :success then :success
      when :warning then :warning
      else :subdued
      end
    end

    # Icon name for the current alert type.
    # @return [String]
    def icon_name
      case type
      when :danger then :x_circle
      when :success then :check_circle
      when :warning then :warning_circle
      else :info
      end
    end

    def classes_for_dismiss
      default_classes = 'inline-flex items-center justify-center w-5 h-5 rounded-md text-slate-400'\
                        'focus-visible:outline-none focus-visible:outline-2 focus-visible:outline-slate-500'\
                        'focus-visible:outline-offset-2 transition-colors duration-200 dark:text-slate-500 '\
                        'dark:hover:text-slate-400 dark:focus:ring-slate-400 hover:text-slate-600 hover:cursor-pointer'
      hover_color_classes = case type
                            when :danger
                              'hover:bg-red-200 hover:dark:bg-red-700'
                            when :info
                              'hover:bg-blue-200 hover:dark:bg-blue-700'
                            when :success
                              'hover:bg-green-200 hover:dark:bg-green-700'
                            when :warning
                              'hover:bg-amber-200 hover:dark:bg-amber-700'
                            else
                              'hover:bg-slate-200 hover:dark:bg-slate-700'
                            end
      class_names(default_classes, hover_color_classes)
    end

    # Stable ID used to wire the alert element with its dismiss button via data attributes.
    # @return [String]
    def alert_id
      @alert_id ||= "alert-#{type}-#{object_id}"
    end

    # ID for the dismiss button.
    # @return [String]
    def dismiss_button_id
      @dismiss_button_id ||= "#{alert_id}-dismiss"
    end

    # Data attributes consumed by the Stimulus controller.
    # @return [Hash]
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
  end
end
