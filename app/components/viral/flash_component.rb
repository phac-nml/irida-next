# frozen_string_literal: true

module Viral
  # A ViewComponent to display flash messages (e.g., success, error, warning, info)
  # with appropriate styling and an optional timeout for auto-dismissal.
  #
  # @param type [Symbol, String] The type of flash message (stored as Symbol internally).
  #        Accepted values: :success, :error, :warning, :info, :notice, :alert.
  #        :notice will be treated as :info.
  #        :alert will be treated as :error.
  # @param data [String] The content of the flash message.
  # @param timeout [Integer] The duration in milliseconds before the flash message auto-dismisses.
  #        Defaults to DEFAULT_TIMEOUT. Error messages do not time out by default (timeout set to 0).
  class FlashComponent < Component
    # @return [Symbol] one of :success, :error, :warning, :info
    attr_reader :type
    # @return [String] the flash message content
    attr_reader :data
    # @return [Integer] timeout duration in milliseconds
    attr_reader :timeout

    # Default duration in milliseconds for auto-dismissal of non-error flash messages.
    DEFAULT_TIMEOUT = 3500

    # Initializes the FlashComponent.
    #
    # @param type [Symbol, String] The type of the flash message.
    # @param data [String] The message content.
    # @param timeout [Integer] The auto-dismiss timeout in milliseconds.
    def initialize(type:, data:, timeout: DEFAULT_TIMEOUT, **system_arguments)
      @type = normalize_type(type.to_sym)
      @data = data
      @timeout = @type == :error ? 0 : timeout
      @system_arguments = system_arguments
    end

    # Build and return the HTML/system arguments hash for the component wrapper.
    #
    # Populates and normalizes `@system_arguments` with sensible defaults used
    # by the flash component (generated `id`, `data` attributes for the
    # Stimulus controller, timeout and type values, CSS classes, ARIA
    # attributes, Turbo permanence, inline style for initial animation, etc.).
    # This method mutates `@system_arguments` in-place and returns the updated
    # hash for rendering (e.g. `tag.div(**system_arguments)`).
    #
    # @return [Hash] attributes suitable for passing to a view helper or tag
    #   when rendering the component wrapper.
    def system_arguments # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      @system_arguments[:id] = @system_arguments[:id] || component_id
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = 'viral--flash'
      @system_arguments[:data]['viral--flash-timeout-value'] = timeout
      @system_arguments[:data]['viral--flash-type-value'] = type
      @system_arguments[:classes] = class_names(
        'flex items-start w-full max-w-md p-4 mb-4 text-slate-700 bg-white rounded-xl shadow-lg border border-slate-200
        dark:text-slate-300 dark:bg-slate-800 dark:border-slate-700 transition-all duration-300 ease-out transform',
        @system_arguments[:classes]
      )
      @system_arguments[:role] = 'alert'
      @system_arguments[:aria] ||= {}
      @system_arguments[:aria][:live] = 'assertive'
      @system_arguments[:aria][:atomic] = 'true'
      @system_arguments[:aria][:describedby] = "#{@system_arguments[:id]}-message"
      @system_arguments[:data][:turbo_permanent] = 'true'
      @system_arguments[:style] = 'opacity: 0; transform: translateY(-20px) scale(0.95);'
      @system_arguments
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
      case type
      when :success
        'text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-200'
      when :error
        'text-red-500 bg-red-100 dark:bg-red-800 dark:text-red-200'
      when :warning
        'text-orange-500 bg-orange-100 dark:bg-orange-700 dark:text-orange-200'
      else
        'text-blue-500 bg-blue-100 dark:bg-blue-800 dark:text-blue-200'
      end
    end

    # Determines the name of the icon to display based on the flash message type.
    #
    # @return [Symbol] The name of the icon.
    def icon_name
      case type
      when :success
        :check_circle
      when :error
        :x_circle
      when :warning
        :warning_circle
      else
        :info # Default icon or handle error
      end
    end

    # Provides the appropriate screen reader text for the flash message type.
    # This text is internationalized and describes the type of message.
    #
    # @return [String] The screen reader text for the message type.
    def message_type_sr_text
      case type
      when :success
        t('common.statuses.success')
      when :error
        t('common.statuses.error')
      when :warning
        t('components.flash.warning_message')
      else
        t('components.flash.information_message')
      end
    end

    private

    # Normalizes the flash message type.
    # :notice is mapped to :info.
    # :alert is mapped to :error.
    # Other types are used as is.
    #
    # @param type_symbol [Symbol] The raw type symbol.
    # @return [Symbol] The normalized type symbol (:success, :error, :warning, :info).
    def normalize_type(type_symbol)
      case type_symbol
      when :notice
        :info
      when :alert
        :error
      else
        type_symbol
      end
    end

    def icon_color
      case type
      when :success
        :success
      when :error
        :danger
      when :warning
        :warning
      else
        :blue
      end
    end
  end
end
