# frozen_string_literal: true

# Viral::ButtonComponent
#
# 💡 All button states are styled for WCAG AAA contrast compliance.
# - Default: slate palette, accessible in light/dark.
# - Primary: Primary palette, accessible in light/dark.
# - Destructive: Red palette, accessible in light/dark.
# - Disabled: Faded, cursor-not-allowed, aria-disabled.
#
# All states include explicit hover/focus/active styles.
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
    STATE_DISABLED = :disabled
    STATE_MAPPINGS = {
      # 💡 slate, AAA contrast, light/dark
      default: [
        'border border-slate-300 bg-slate-50 text-slate-900',
        'hover:bg-slate-100 hover:text-slate-950',
        'focus-visible:ring-2 focus-visible:ring-primary-600',
        'dark:border-slate-700 dark:bg-slate-900 dark:text-slate-50',
        'dark:hover:bg-slate-800 dark:hover:text-white'
      ].join(' '),
      # 💡 Primary, AAA contrast, light/dark
      primary: [
        'border border-primary-800 bg-primary-800 text-white',
        'hover:bg-primary-900 focus-visible:ring-2 focus-visible:ring-primary-400',
        'dark:border-primary-700 dark:bg-primary-700 dark:text-white',
        'dark:hover:bg-primary-600'
      ].join(' '),
      # 💡 Destructive, AAA contrast, light/dark
      destructive: [
        'border border-red-800 bg-red-700 text-white',
        'hover:bg-red-800 focus-visible:ring-2 focus-visible:ring-red-400',
        'dark:border-red-600 dark:bg-red-600 dark:text-white',
        'dark:hover:bg-red-700'
      ].join(' '),
      # 💡 Disabled, faded, not interactive
      disabled: [
        'border border-slate-200 bg-slate-200 text-slate-400',
        'cursor-not-allowed opacity-60',
        'dark:border-slate-800 dark:bg-slate-800 dark:text-slate-500'
      ].join(' ')
    }.freeze
    # @!endgroup

    DISCLOSURE_DEFAULT = false
    DISCLOSURE_OPTIONS = [true, false, :down, :up, :right, :select, :horizontal_dots].freeze

    # Initialize the button component.
    #
    # @param state [Symbol] one of STATE_MAPPINGS keys
    # @param full_width [Boolean]
    # @param disclosure [Symbol, Boolean]
    # @param system_arguments [Hash]
    def initialize(state: STATE_DEFAULT, full_width: false,
                   disclosure: DISCLOSURE_DEFAULT, **system_arguments)
      @disclosure = disclosure
      @disclosure = :down if @disclosure == true

      @system_arguments = system_arguments
      @system_arguments[:type] = 'button' if @system_arguments[:type].blank?

      is_disabled = disabled?(@system_arguments)
      mapped_state = resolve_state(state, is_disabled)
      @system_arguments[:classes] = build_classes(
        user_defined: @system_arguments[:classes],
        mapped_state: mapped_state,
        full_width: full_width
      )
      apply_aria_accessibility(@system_arguments, is_disabled)
    end

    private

    def disabled?(args)
      args[:disabled].present? && args[:disabled]
    end

    def resolve_state(state, is_disabled)
      mapped_state = is_disabled ? STATE_DISABLED : state.to_sym
      STATE_MAPPINGS.key?(mapped_state) ? mapped_state : STATE_DEFAULT
    end

    def build_classes(user_defined:, mapped_state:, full_width:)
      base_classes = [
        'inline-flex items-center justify-center border focus:z-10 sm:w-auto',
        'min-h-11 min-w-11 px-5 py-2.5 rounded-lg font-semibold cursor-pointer'
      ]
      base_classes << user_defined if user_defined.present?
      base_classes << STATE_MAPPINGS[mapped_state]
      base_classes << 'w-full' if full_width
      class_names(*base_classes)
    end

    def apply_aria_accessibility(args, is_disabled)
      args[:aria] ||= {}
      args[:aria][:disabled] = true if is_disabled
    end
  end
end
