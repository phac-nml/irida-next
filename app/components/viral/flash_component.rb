# frozen_string_literal: true

module Viral
  # A ViewComponent to display flash messages (e.g., success, error, warning, info)
  # with appropriate styling and an optional timeout for auto-dismissal.
  #
  # @param type [String, Symbol] The type of flash message.
  #        Accepted values: :success, :error, :warning, :info, :notice, :alert.
  #        :notice will be treated as :info.
  #        :alert will be treated as :error.
  # @param data [String] The content of the flash message.
  # @param timeout [Integer] The duration in milliseconds before the flash message auto-dismisses.
  #        Defaults to DEFAULT_TIMEOUT. Error messages do not time out by default (timeout set to 0).
  class FlashComponent < Component
    attr_reader :type, :data, :timeout

    # Default duration in milliseconds for auto-dismissal of non-error flash messages.
    DEFAULT_TIMEOUT = 3500

    # Initializes the FlashComponent.
    #
    # @param type [String, Symbol] The type of the flash message.
    # @param data [String] The message content.
    # @param timeout [Integer] The auto-dismiss timeout in milliseconds.
    def initialize(type:, data:, timeout: DEFAULT_TIMEOUT)
      @type = normalize_type(type.to_s)
      @data = data
      @timeout = @type == 'error' ? 0 : timeout
    end

    # Generates a unique ID for the flash component.
    #
    # @return [String] The unique ID string.
    def component_id
      "toast-#{type}-#{object_id}"
    end

    # Generates the CSS classes for the icon's container div.
    # Classes vary based on the flash message type to provide distinct visual cues.
    #
    # @return [String] The CSS classes for the icon container.
    def icon_container_classes
      case type.to_s
      when 'success'
        'text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-200'
      when 'error'
        'text-red-500 bg-red-100 dark:bg-red-800 dark:text-red-200'
      when 'warning'
        'text-orange-500 bg-orange-100 dark:bg-orange-700 dark:text-orange-200'
      when 'info'
        'text-blue-500 bg-blue-100 dark:bg-blue-800 dark:text-blue-200'
      else
        '' # Default or fallback classes if needed
      end
    end

    # Determines the name of the icon to display based on the flash message type.
    #
    # @return [String] The name of the icon.
    def icon_name
      case type.to_s
      when 'success'
        :check_CIRCLE
      when 'error'
        :'x-circle'
      when 'warning'
        'warning-circle'
      when 'info'
        :info
      else
        '' # Default icon or handle error
      end
    end

    # Provides the appropriate screen reader text for the flash message type.
    # This text is internationalized and describes the type of message.
    #
    # @return [String] The screen reader text for the message type.
    def message_type_sr_text
      case type.to_s
      when 'success'
        t('components.flash.success_message')
      when 'error'
        t('components.flash.error_message')
      when 'warning'
        t('components.flash.warning_message')
      when 'info'
        t('components.flash.information_message')
      else
        t('components.flash.message')
      end
    end

    private

    # Normalizes the flash message type.
    # 'notice' is mapped to 'info'.
    # 'alert' is mapped to 'error'.
    # Other types are used as is.
    #
    # @param type_string [String] The raw type string.
    # @return [String] The normalized type string ('success', 'error', 'warning', 'info').
    def normalize_type(type_string)
      case type_string
      when 'notice'
        'info'
      when 'alert'
        'error'
      else
        type_string
      end
    end
  end
end
