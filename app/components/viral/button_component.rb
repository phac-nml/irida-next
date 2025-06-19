# frozen_string_literal: true

module Viral
  # Viral component for buttons
  class ButtonComponent < Viral::Component
    attr_reader :disclosure, :tag

    STATE_DEFAULT = :default
    STATE_MAPPINGS = {
      STATE_DEFAULT => 'button-default',
      :primary => 'button-primary',
      :destructive => 'button-destructive'
    }.freeze

    DISCLOSURE_DEFAULT = false
    DISCLOSURE_OPTIONS = [true, false, :down, :up, :select, :horizontal_dots].freeze

    def initialize(state: STATE_DEFAULT, full_width: false,
                   disclosure: DISCLOSURE_DEFAULT, **system_arguments)
      @disclosure = disclosure
      @disclosure = :down if @disclosure == true

      @system_arguments = system_arguments
      @system_arguments[:type] = 'button' if @system_arguments[:type].blank?
      user_defined_classes = @system_arguments[:classes]
      @system_arguments[:classes] = class_names(
        'button',
        user_defined_classes,
        STATE_MAPPINGS[state],
        'w-full': full_width
      )
    end
  end
end
