# frozen_string_literal: true

module Viral
  # @label Flash Component
  # @display bg_color "#fff"
  # @display max_width "600px"
  class FlashComponentPreview < ViewComponent::Preview
    # @!group Types
    # @label Success
    # @param message text "This is a success message."
    # @param timeout number 3500
    def success(message: 'This is a success message.', timeout: 3500)
      render Viral::FlashComponent.new(type: :success, data: message, timeout:)
    end

    # @label Error
    # @param message text "This is an error message."
    def error(message: 'This is an error message.')
      render Viral::FlashComponent.new(type: :error, data: message, timeout:)
    end

    # @label Warning
    # @param message text "This is a warning message."
    # @param timeout number 3500
    def warning(message: 'This is a warning message.', timeout: 3500)
      render Viral::FlashComponent.new(type: :warning, data: message, timeout:)
    end

    # @label Info
    # @param message text "This is an info message."
    # @param timeout number 3500
    def info(message: 'This is an info message.', timeout: 3500)
      render Viral::FlashComponent.new(type: :info, data: message, timeout:)
    end

    # @label Notice (maps to Info)
    # @param message text "This is a notice message."
    # @param timeout number 3500
    def notice(message: 'This is a notice message.', timeout: 3500)
      render Viral::FlashComponent.new(type: :notice, data: message, timeout:)
    end

    # @label Alert (maps to Error)
    # @param message text "This is an alert message."
    # @param timeout number 0
    def alert(message: 'This is an alert message.', timeout: 0)
      render Viral::FlashComponent.new(type: :alert, data: message, timeout:)
    end
    # @!endgroup
  end
end
