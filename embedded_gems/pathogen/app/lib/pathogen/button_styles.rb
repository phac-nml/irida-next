# frozen_string_literal: true

module Pathogen
  # This module contains all the styling logic for Pathogen buttons.
  # It provides a consistent way to generate button styles across the application.
  module ButtonStyles
    extend ActiveSupport::Concern
    include ActionView::Helpers::TagHelper

    # Default classes applied to all buttons
    DEFAULT_CLASSES = 'relative cursor-pointer font-medium text-center items-center ' \
                      'inline-flex gap-2 select-none rounded ' \
                      'disabled:opacity-70 disabled:cursor-not-allowed transition ease-in ' \
                      'active:transition-none border border-1'

    # Available color schemes for buttons
    SCHEME_OPTIONS = %i[primary default danger].freeze
    DEFAULT_SCHEME = :default

    # Default size for buttons
    DEFAULT_SIZE = :base

    # A hash of predefined button size mappings
    SIZE_MAPPINGS = {
      xs: 'px-2.5 py-1.5 text-xs',
      sm: 'px-3 py-2 text-sm leading-4',
      base: 'px-4 py-2 text-sm',
      lg: 'px-4 py-2 text-base',
      xl: 'px-6 py-3 text-base'
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys

    # A hash of predefined icon size mappings
    ICON_SIZES = {
      xs: 'w-3 h-3',
      sm: 'w-3.5 h-3.5',
      base: 'w-4 h-4',
      lg: 'w-5 h-5',
      xl: 'w-6 h-6'
    }.freeze

    # Generate all classes for a button based on its configuration
    # @param scheme [Symbol] The button's color scheme
    # @param size [Symbol] The button's size
    # @param block [Boolean] Whether the button is full-width
    # @param disabled [Boolean] Whether the button is disabled
    # @param custom_classes [String] Additional custom classes to add
    # @return [String] All CSS classes for the button
    def generate_classes(scheme:, size:, block: false, disabled: false, custom_classes: nil)
      classes = []
      classes << DEFAULT_CLASSES
      classes << scheme_classes(scheme, disabled: disabled)
      classes << size_classes(size)
      classes << 'w-full' if block
      classes << custom_classes if custom_classes.present?
      classes.compact.join(' ')
    end

    # Generate classes for a specific color scheme
    # @param scheme [Symbol] The button's color scheme
    # @param disabled [Boolean] Whether the button is disabled
    # @return [String] CSS classes for the color scheme
    def scheme_classes(scheme, disabled: false)
      case scheme.to_sym
      when :primary then primary_style(disabled: disabled)
      when :danger then danger_style(disabled: disabled)
      else default_style(disabled: disabled)
      end
    end

    private

    def size_classes(size)
      SIZE_MAPPINGS[size]
    end

    def default_style(disabled: false)
      class_names(
        'text-slate-950 bg-slate-50 border-slate-200',
        'dark:text-slate-100 dark:bg-slate-800 dark:border-slate-600',
        {
          'hover:bg-slate-200 dark:hover:bg-slate-600' => !disabled
        }
      )
    end

    def primary_style(disabled: false)
      class_names(
        'border-transparent text-white bg-primary-600 border-primary-600',
        'dark:bg-primary-700',
        {
          'hover:bg-primary-700 dark:hover:bg-primary-800' => !disabled
        }
      )
    end

    def danger_style(disabled: false)
      class_names(
        'border-transparent text-white bg-red-600',
        'dark:bg-red-700',
        {
          'hover:bg-red-700 dark:hover:bg-red-800' => !disabled
        }
      )
    end
  end
end
