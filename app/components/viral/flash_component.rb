# frozen_string_literal: true

module Viral
  # View Component for UI flash messages
  class FlashComponent < Component
    attr_reader :type, :data, :timeout, :icon, :classes

    DEFAULT_TIMEOUT = 3500

    def initialize(type:, data:, timeout: DEFAULT_TIMEOUT)
      @type = type
      @data = data
      @timeout = timeout
    end
  end
end
