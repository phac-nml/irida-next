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
