# frozen_string_literal: true

module Pathogen
  # The Button component provides a flexible, accessible button with multiple visual styles and states.
  # It supports various color schemes, sizes, and can include leading/trailing visual elements.
  #
  # @example Basic usage
  #   <%= render Pathogen::ButtonComponent.new(type: :button) { "Click me" } %>
  #
  # @example With scheme and size
  #   <%= render Pathogen::ButtonComponent.new(
  #     scheme: :primary,
  #     size: :medium,
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
    SCHEME_OPTIONS = %i[primary default danger ghost].freeze
    DEFAULT_SCHEME = :default

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

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      setup_button_classes
    end

    # Called before rendering to handle visual elements
    def before_render
      add_visual_styles if leading_visual.present? || trailing_visual.present?
    end

    private

    def setup_button_classes
      scheme_class = generate_scheme_class(
        fetch_or_fallback(SCHEME_OPTIONS, @scheme, DEFAULT_SCHEME)
      )

      @system_arguments[:classes] = class_names(
        @system_arguments[:class],
        scheme_class,
        'block w-full' => @block
      )
    end

    def add_visual_styles
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        'text-center inline-flex items-center'
      )
    end

    # Generates the appropriate CSS classes for the button's color scheme
    #
    # @param scheme [Symbol] The color scheme to generate classes for
    # @return [String] CSS classes for the specified scheme
    def generate_scheme_class(scheme)
      scheme_classes = {
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
      }


      scheme_classes[scheme].join(' ')
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
