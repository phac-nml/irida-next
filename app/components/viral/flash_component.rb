# frozen_string_literal: true

module Viral
  # View Component for UI flash messages
  class FlashComponent < Component
    attr_reader :type, :data, :timeout, :icon, :classes

    DEFAULT_TIMEOUT = 5000

    def initialize(type:, data:, timeout: DEFAULT_TIMEOUT)
      @type = type_for_flash(type)
      @data = data
      @timeout = type.to_s == 'error' ? 0 : timeout
    end

    def type_for_flash(type)
      @type = if type == 'notice'
                'info'
              else
                type == 'alert' ? 'error' : type
              end
    end
  end
end
