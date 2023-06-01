# frozen_string_literal: true

module Viral
  # Viral component for buttons
  class ButtonComponent < Viral::Component
    attr_reader :disclosure, :tag

    TYPE_DEFAULT = :default
    TYPE_MAPPINGS = {
      TYPE_DEFAULT => 'button--state-default',
      :primary => 'button--state-primary',
      :destructive => 'button--state-destructive'
    }.freeze

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      :small => 'button--size-small',
      SIZE_DEFAULT => 'button--size-default',
      :large => 'button--size-large'
    }.freeze

    DISCLOSURE_DEFAULT = false
    DISCLOSURE_OPTIONS = [true, false, :down, :up, :select, :horizontal_dots].freeze

    def initialize(type: TYPE_DEFAULT, size: SIZE_DEFAULT, full_width: false, disclosure: DISCLOSURE_DEFAULT,
                   **system_arguments)

      @disclosure = disclosure
      @disclosure = :down if disclosure == true

      @system_arguments = system_arguments
      @system_arguments[:classes] = class_names(
        'button',
        @system_arguments[:classes],
        TYPE_MAPPINGS[type],
        SIZE_MAPPINGS[size],
        'w-full': full_width
      )
    end
  end
end
