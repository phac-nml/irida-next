# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::Button component, which is a customizable button
  # with various schemes, sizes, and styling options. It's part of the Pathogen
  # component library and provides a flexible way to create buttons with consistent
  # styling across the application.
  #
  class Button < Pathogen::Component
    include Pathogen::ButtonSizes
    include Pathogen::ButtonVisuals

    SCHEME_OPTIONS = %i[primary default danger].freeze
    DEFAULT_SCHEME = :default
    # rubocop:disable Layout/LineLength
    DEFAULT_CLASSES = 'relative pointer select-none rounded-lg font-medium focus:outline-none focus:ring-4 focus:z-10 disabled:opacity-70 disabled:cursor-not-allowed'
    # rubocop:enable Layout/LineLength

    # CSS classes for different button schemes
    PRIMARY_SCHEME_CLASSES = [
      'bg-light-brand-primary',
      'text-light-onbrand-primary',
      'border',
      'border-light-brand-primary',
      'disabled:hover:bg-light-brand-primary hover:bg-light-brand-primary-hover',
      'focus:ring-light-brand-primary'
    ].freeze

    PRIMARY_DARK_SCHEME_CLASSES = [
      'dark:bg-dark-brand-primary',
      'dark:text-dark-onbrand-primary',
      'dark:border-dark-brand-primary',
      'dark:disabled:hover:bg-dark-brand-primary dark:hover:bg-dark-brand-primary-hover',
      'dark:focus:ring-dark-brand-primary'
    ].freeze

    DEFAULT_SCHEME_CLASSES = [
      'bg-light-neutral-primary',
      'text-light-onneutral-primary',
      'border',
      'border-light-neutral-primary',
      'disabled:hover:bg-light-neutral-primary hover:bg-light-neutral-primary-hover',
      'focus:ring-light-neutral-primary'
    ].freeze

    DEFAULT_DARK_SCHEME_CLASSES = [
      'dark:bg-dark-neutral-primary',
      'dark:text-dark-onneutral-primary',
      'dark:border-dark-neutral-primary',
      'dark:disabled:hover:bg-dark-neutral-primary dark:hover:bg-dark-neutral-primary-hover',
      'dark:focus:ring-dark-neutral-primary'
    ].freeze

    DANGER_SCHEME_CLASSES = [
      'bg-light-danger-primary',
      'text-light-ondanger-primary',
      'border',
      'border-light-danger-primary',
      'disabled:hover:bg-light-danger-primary hover:bg-light-danger-primary-hover',
      'focus:ring-light-danger-primary'
    ].freeze

    DANGER_DARK_SCHEME_CLASSES = [
      'dark:bg-dark-danger-primary',
      'dark:text-dark-ondanger-primary',
      'dark:border-dark-danger-primary',
      'dark:disabled:hover:bg-dark-danger-primary dark:hover:bg-dark-danger-primary-hover',
      'dark:focus:ring-dark-danger-primary'
    ].freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(base_button_class: Pathogen::BaseButton, scheme: DEFAULT_SCHEME, size: DEFAULT_SIZE, block: false,
                   disabled: false, **system_arguments)
      @base_button_class = base_button_class
      @scheme = scheme
      @size = size
      @block = block

      @system_arguments = system_arguments
      @system_arguments[:disabled] = disabled

      @id = @system_arguments[:id]

      @system_arguments[:classes] = class_names(
        system_arguments[:class],
        generate_scheme_mapping(fetch_or_fallback(SCHEME_OPTIONS, scheme, DEFAULT_SCHEME)),
        SIZE_MAPPINGS[fetch_or_fallback(SIZE_OPTIONS, size, DEFAULT_SIZE)],
        DEFAULT_CLASSES,
        'block w-full' => block
      )
    end

    # rubocop:enable Metrics/ParameterLists

    def before_render
      return unless leading_visual.present? || trailing_visual.present?

      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        'text-center inline-flex items-center'
      )
    end

    private

    # Trims the content by removing leading and trailing whitespace.
    # If the content is blank, returns nil.
    # If the content is marked as HTML safe, ensures the trimmed content remains HTML safe.
    #
    # @return [String, nil] The trimmed content, or nil if the content is blank.
    def trimmed_content
      return if content.blank?

      trimmed_content = content.strip

      return trimmed_content unless content.html_safe?

      # strip unsets `html_safe`, so we have to set it back again to guarantee that HTML blocks won't break
      trimmed_content.html_safe # rubocop:disable Rails/OutputSafety
    end

    # Generates the appropriate CSS classes for the button's color scheme and tag type.
    #
    # @param scheme [Symbol] The color scheme of the button (:primary, :default, or :danger).
    # @return [String] A string of CSS classes corresponding to the specified scheme.
    def generate_scheme_mapping(scheme)
      case scheme
      when :primary
        (PRIMARY_SCHEME_CLASSES + PRIMARY_DARK_SCHEME_CLASSES).join(' ')
      when :default
        (DEFAULT_SCHEME_CLASSES + DEFAULT_DARK_SCHEME_CLASSES).join(' ')
      when :danger
        (DANGER_SCHEME_CLASSES + DANGER_DARK_SCHEME_CLASSES).join(' ')
      else
        # Default case for other schemes or fallback
        ''
      end
    end
  end
end
