# frozen_string_literal: true

module Viral
  # View Component for UI flash messages
  class FlashComponent < Component
    attr_reader :type, :data, :timeout, :icon, :classes

    DEFAULT_TIMEOUT = 3500

    def initialize(type:, data:, timeout: DEFAULT_TIMEOUT)
      @type = set_type(type)
      @data = data
      @timeout = type.to_s == 'error' ? 0 : timeout
    end

    def set_type(type)
      @type = if type == 'notice'
                'info'
              else
                type == 'alert' ? 'error' : type
              end
    end
  end
end
