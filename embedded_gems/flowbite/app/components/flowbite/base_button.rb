# frozen_string_literal: true

module Flowbite
  class BaseButton < Flowbite::Component
    DEFAULT_TAG = :button
    TAG_OPTIONS = [DEFAULT_TAG, :a].freeze

    DEFAULT_TYPE = :button
    TYPE_OPTIONS = [DEFAULT_TYPE, :submit, :reset].freeze

    attr_reader :disabled
    alias disabled? disabled

    def initialize(tag: DEFAULT_TAG, type: DEFAULT_TYPE, block: false, disabled: false, inactive: false,
                   **system_arguments)
      @system_arguments = system_arguments
      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, DEFAULT_TAG)

      if @system_arguments[:tag] == :button
        @system_arguments[:type] =
          fetch_or_fallback(TYPE_OPTIONS, type, DEFAULT_TYPE)
      end

      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        'btn-block' => block,
        'Button--inactive' => inactive
      )

      @disabled = disabled
      return unless @disabled

      @system_arguments[:tag] = :button
      @system_arguments[:disabled] = ''
    end

    def call
      render(Flowbite::BaseComponent.new(**@system_arguments)) { content }
    end
  end
end
