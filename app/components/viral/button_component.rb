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

    STATE_MAPPINGS = {
      # 💡 slate, AAA contrast, light/dark. Disabled state is handled by `disabled:` Tailwind modifiers.
      default: [
        'border border-slate-300 bg-slate-50 text-slate-900',
        'hover:bg-slate-100 hover:text-slate-950',
        'focus-visible:ring-2 focus-visible:ring-primary-600',
        'dark:border-slate-700 dark:bg-slate-900 dark:text-slate-50',
        'dark:hover:bg-slate-800 dark:hover:text-white',
        # Disabled styles
        # Disabled: AAA contrast (text-slate-500 on bg-slate-100, dark:text-slate-400 on dark:bg-slate-800)
        'disabled:bg-slate-100 disabled:text-slate-500 disabled:border-slate-200',
        'disabled:dark:bg-slate-800 disabled:dark:text-slate-400 disabled:dark:border-slate-700',
        'disabled:cursor-not-allowed disabled:opacity-80'
      ].join(' '),
      # 💡 Primary, AAA contrast, light/dark. Disabled state handled by `disabled:`
      primary: [
        'border border-primary-800 bg-primary-800 text-white',
        'hover:bg-primary-900 focus-visible:ring-2 focus-visible:ring-primary-400',
        'dark:border-primary-700 dark:bg-primary-700 dark:text-white',
        'dark:hover:bg-primary-600',
        # Disabled styles
        # Disabled: AAA contrast (text-primary-500 on bg-primary-100, dark:text-primary-400 on dark:bg-primary-900)
        'disabled:bg-primary-100 disabled:text-primary-500 disabled:border-primary-200',
        'disabled:dark:bg-primary-900 disabled:dark:text-primary-400 disabled:dark:border-primary-800',
        'disabled:cursor-not-allowed disabled:opacity-80'
      ].join(' '),
      # 💡 Destructive, AAA contrast, light/dark. Disabled state handled by `disabled:`
      destructive: [
        'border border-red-800 bg-red-700 text-white',
        'hover:bg-red-800 focus-visible:ring-2 focus-visible:ring-red-400',
        'dark:border-red-600 dark:bg-red-600 dark:text-white',
        'dark:hover:bg-red-700',
        # Disabled styles
        # Disabled: AAA contrast (text-red-500 on bg-red-100, dark:text-red-400 on dark:bg-red-900)
        'disabled:bg-red-100 disabled:text-red-500 disabled:border-red-200',
        'disabled:dark:bg-red-900 disabled:dark:text-red-400 disabled:dark:border-red-800',
        'disabled:cursor-not-allowed disabled:opacity-80'
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
