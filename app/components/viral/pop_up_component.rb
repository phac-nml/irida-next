# frozen_string_literal: true

module Viral
  class PopUpComponent < Component
    attr_reader :button_text

    def initialize(button_text:, **system_arguments)
      @button_text = button_text
      @system_arguments = system_arguments
    end
  end
end
