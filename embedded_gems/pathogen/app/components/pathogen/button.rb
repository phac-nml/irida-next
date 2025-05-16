# frozen_string_literal: true

module Pathogen
  # The Button component provides a flexible, accessible button with multiple visual styles and states.
  # It supports various color schemes and can include leading/trailing visual elements.
  #
  # @example Basic usage
  #   <%= render Pathogen::ButtonComponent.new(type: :button) { "Click me" } %>
  #
  # @example With scheme
  #   <%= render Pathogen::ButtonComponent.new(
  #     scheme: :primary,
  #     disabled: false
  #   ) { "Submit" } %>
  #
  # @example With icons
  #   <%= render Pathogen::ButtonComponent.new do |c| %>
  #     <% c.leading_visual(icon: :check) %>
  #     Submit
  #   <% end %>
  #
  class Button < Pathogen::Component
    include Pathogen::ButtonVisuals

    # Available color schemes for the button
    SCHEME_OPTIONS = %i[primary default danger ghost unstyled].freeze
    DEFAULT_SCHEME = :default

    SCHEME_CLASSES = {
      primary: %w[
        border-primary-800 bg-primary-800 hover:bg-primary-900
        dark:border-primary-700 dark:bg-primary-700 dark:hover:bg-primary-600
        disabled:bg-primary-100 disabled:text-primary-500 disabled:border-primary-200
        disabled:dark:bg-primary-900 disabled:dark:text-primary-400
        disabled:dark:border-primary-800 text-white dark:text-white
      ],
      default: %w[
        border-slate-300 bg-slate-50 text-slate-900 hover:bg-slate-100
        hover:text-slate-950 disabled:border-slate-200 disabled:bg-slate-100
        disabled:text-slate-500 dark:border-slate-700 dark:bg-slate-900
        dark:text-slate-50 dark:hover:bg-slate-800 dark:hover:text-white
        disabled:dark:border-slate-700 disabled:dark:bg-slate-800
        disabled:dark:text-slate-400
      ],
      danger: %w[
        border-red-800 bg-red-700 text-white hover:bg-red-800
        disabled:border-red-200 disabled:bg-red-100 disabled:text-red-500
        dark:border-red-600 dark:bg-red-600 dark:text-white
        dark:hover:bg-red-700 disabled:dark:border-red-800
        disabled:dark:bg-red-900 disabled:dark:text-red-400
      ],
      ghost: %w[
        border-transparent bg-transparent text-slate-700 hover:bg-slate-100
        hover:text-slate-900 disabled:text-slate-400 dark:text-slate-300
        dark:hover:bg-slate-800 dark:hover:text-white disabled:dark:text-slate-600
      ]
    }.freeze

    # @param base_button_class [Class] The base button class to use for rendering
    # @param scheme [Symbol] The color scheme to apply (default: :default)
    # @param block [Boolean] Whether the button should be a block-level element
    # @param disabled [Boolean] Whether the button is disabled
    # @param system_arguments [Hash] Additional HTML attributes to be passed to the button
    def initialize(
      base_button_class: Pathogen::BaseButton,
      scheme: DEFAULT_SCHEME,
      block: false,
      disabled: false,
      **system_arguments
    )
      @base_button_class = base_button_class
      @scheme = scheme
      @block = block

      # Consolidate user-provided :class and :classes attributes into :class for internal processing.
      # This ensures that subsequent modifications to @system_arguments[:class] build upon all user inputs.
      # We operate on a copy of system_arguments initially to safely delete keys.
      processed_system_arguments = system_arguments.dup
      user_class_attr = processed_system_arguments.delete(:class)
      user_classes_attr = processed_system_arguments.delete(:classes)
      consolidated_user_classes = class_names(user_class_attr, user_classes_attr)

      @system_arguments = processed_system_arguments # Contains remaining system_arguments
      @system_arguments[:class] = consolidated_user_classes # Prime :class with all user-provided classes

      @system_arguments[:disabled] = disabled

      # Pass apply_default_base_styles: false if scheme is :unstyled
      @system_arguments[:apply_default_base_styles] = false if @scheme == :unstyled

      setup_button_classes
    end

    # Called before rendering to handle visual elements
    def before_render
      add_visual_styles if (leading_visual.present? || trailing_visual.present?) && @scheme != :unstyled
    end

    private

    def setup_button_classes
      # If unstyled, only use provided classes and block status
      if @scheme == :unstyled
        @system_arguments[:class] = class_names(
          @system_arguments[:class],
          'block w-full' => @block
        )
        return
      end

      scheme_class = generate_scheme_class(
        fetch_or_fallback(SCHEME_OPTIONS, @scheme, DEFAULT_SCHEME)
      )

      @system_arguments[:class] = class_names(
        @system_arguments[:class],
        scheme_class,
        'block w-full' => @block
      )
    end

    def add_visual_styles
      @system_arguments[:class] = class_names(
        @system_arguments[:class],
        'text-center inline-flex items-center'
      )
    end

    # Generates the appropriate CSS classes for the button's color scheme
    #
    # @param scheme [Symbol] The color scheme to generate classes for
    # @return [String] CSS classes for the specified scheme
    def generate_scheme_class(scheme)
      return '' if scheme == :unstyled

      SCHEME_CLASSES[scheme].join(' ')
    end

    # Trims the content while preserving HTML safety
    #
    # @return [String, nil] The trimmed content, or nil if blank
    def trimmed_content
      return if content.blank?

      trimmed = content.strip
      content.html_safe? ? trimmed.html_safe : trimmed # rubocop:disable Rails/OutputSafety
    end
  end
end
