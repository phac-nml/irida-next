# frozen_string_literal: true

# Viral::ButtonComponent
#
# 💡 All button states are styled for WCAG AAA contrast compliance.
# - Default: slate palette, accessible in light/dark.
# - Primary: Primary palette, accessible in light/dark.
# - Destructive: Red palette, accessible in light/dark.
# - Disabled: Faded, cursor-not-allowed, aria-disabled.
#
# All states include explicit hover/active styles. Default browser focus is used.
module Viral
  # Renders a highly accessible, theme-aware button.
  #
  # @param state [Symbol] visual state (:default, :primary, :destructive, :disabled)
  # @param full_width [Boolean] whether the button should take full width
  # @param disclosure [Symbol, Boolean] optional disclosure icon (:down, :up, :right, etc.)
  # @param system_arguments [Hash] additional arguments for rendering
  class ButtonComponent < Viral::Component
    attr_reader :disclosure, :tag

    # @!group State mappings (WCAG AAA)
    STATE_DEFAULT = :default

    # DRY mapping to new Tailwind utility classes
    STATE_MAPPINGS = {
      default: 'btn-default',
      primary: 'btn-primary',
      destructive: 'btn-destructive'
    }.freeze

    # Supported shape variants
    SHAPE_MAPPINGS = {
      rounded: 'btn-rounded',
      square: 'btn-square',
      left: 'btn-left',
      right: 'btn-right'
    }.freeze
    # @!endgroup

    DISCLOSURE_DEFAULT = false
    DISCLOSURE_OPTIONS = [true, false, :down, :up, :right].freeze

    # Initialize the button component.
    #
    # @param state [Symbol] one of STATE_MAPPINGS keys
    # @param full_width [Boolean]
    # @param disclosure [Symbol, Boolean]
    # @param system_arguments [Hash]
    # @param shape [Symbol] :rounded (default), :square, :left, :right
    def initialize(state: STATE_DEFAULT, full_width: false,
                   disclosure: DISCLOSURE_DEFAULT, shape: :rounded, **system_arguments)
      @disclosure = disclosure
      @disclosure = :down if @disclosure == true

      @system_arguments = system_arguments
      @system_arguments[:type] = 'button' if @system_arguments[:type].blank?

      is_disabled = disabled?(@system_arguments)
      mapped_state = resolve_state(state, is_disabled)
      mapped_shape = resolve_shape(shape)
      @system_arguments[:classes] = build_classes(
        user_defined: @system_arguments[:classes],
        mapped_state: mapped_state,
        mapped_shape: mapped_shape,
        full_width: full_width
      )
      apply_aria_accessibility(@system_arguments, is_disabled)
      # Tailwind's `disabled:` handles all visual states; no need to map `:disabled` state.
    end

    private

    def disabled?(args)
      args[:disabled].present? && args[:disabled]
    end

    def resolve_state(state, _is_disabled)
      mapped_state = state.to_sym
      STATE_MAPPINGS.key?(mapped_state) ? mapped_state : STATE_DEFAULT
    end

    # Compose the button classes using DRY utility classes
    def build_classes(user_defined:, mapped_state:, mapped_shape:, full_width:)
      base_classes = [
        'btn',
        STATE_MAPPINGS[mapped_state],
        SHAPE_MAPPINGS[mapped_shape]
      ]
      base_classes << user_defined if user_defined.present?
      base_classes << 'w-full' if full_width
      class_names(*base_classes)
    end

    def resolve_shape(shape)
      mapped_shape = shape.to_sym
      SHAPE_MAPPINGS.key?(mapped_shape) ? mapped_shape : :rounded
    end

    def apply_aria_accessibility(args, is_disabled)
      args[:aria] ||= {}
      args[:aria][:disabled] = true if is_disabled
    end
  end
end
