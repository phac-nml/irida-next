# frozen_string_literal: true

module Viral
  class PopUpComponent < Component
    attr_reader :title, :button_text

    renders_one :header
    renders_one :body
    renders_one :footer

    def initialize(button_text:, **system_arguments)
      @button_text = button_text
      @system_arguments = system_arguments
    end
  end
end
