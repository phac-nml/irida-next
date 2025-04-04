# frozen_string_literal: true

module Pathogen
  # 🎨 ButtonStyles: A comprehensive styling system for Pathogen buttons
  #
  # This module provides a consistent and maintainable approach to button styling
  # across the application. It leverages TailwindCSS classes to create beautiful,
  # accessible, and responsive buttons.
  #
  # @example Basic usage
  #   generate_classes(scheme: :primary, size: :base) # => "... tailwind classes ..."
  #
  # @example With block and custom classes
  #   generate_classes(
  #     scheme: :danger,
  #     size: :lg,
  #     block: true,
  #     custom_classes: "my-custom-class"
  #   )
  module ButtonStyles
    extend ActiveSupport::Concern
    include ActionView::Helpers::TagHelper

    # 🎯 Core button styles applied to all variants
    DEFAULT_CLASSES = [
      'relative cursor-pointer font-medium text-center',
      'inline-flex items-center gap-2 select-none rounded',
      'disabled:opacity-70 disabled:cursor-not-allowed',
      'transition ease-in active:transition-none',
      'border border-1'
    ].join(' ').freeze

    # 🎨 Available button color schemes
    SCHEME_OPTIONS = %i[primary default danger].freeze
    DEFAULT_SCHEME = :default

    # 📏 Button size configuration
    DEFAULT_SIZE = :base

    # 📐 Size-specific padding and text styles
    SIZE_MAPPINGS = {
      sm: 'px-2.5 py-1.5 text-xs',          # Small
      base: 'px-3 py-2 text-sm leading-4',  # Base/Default
      lg: 'px-4 py-2 text-sm'               # Large
    }.freeze
    SIZE_OPTIONS = SIZE_MAPPINGS.keys.freeze

    # 🎯 Generates the complete set of classes for a button
    #
    # @param scheme [Symbol] Button color scheme (:primary, :default, :danger)
    # @param size [Symbol] Button size (:xs, :sm, :base, :lg, :xl)
    # @param block [Boolean] Whether the button should be full-width
    # @param disabled [Boolean] Whether the button is disabled
    # @param custom_classes [String] Additional custom classes to append
    # @return [String] Complete set of Tailwind CSS classes
    def generate_classes(scheme:, size:, block: false, disabled: false, custom_classes: nil)
      [
        DEFAULT_CLASSES,
        scheme_classes(scheme, disabled: disabled),
        size_classes(size),
        ('w-full' if block),
        custom_classes
      ].compact.join(' ')
    end

    # 🎨 Generates scheme-specific classes
    #
    # @param scheme [Symbol] The color scheme to use
    # @param disabled [Boolean] Whether the button is disabled
    # @return [String] Scheme-specific Tailwind CSS classes
    def scheme_classes(scheme, disabled: false)
      case scheme.to_sym
      when :primary then primary_style(disabled: disabled)
      when :danger then danger_style(disabled: disabled)
      else default_style(disabled: disabled)
      end
    end

    private

    # 📏 Retrieves size-specific classes
    #
    # @param size [Symbol] The desired button size
    # @return [String] Size-specific Tailwind CSS classes
    def size_classes(size)
      SIZE_MAPPINGS[size]
    end

    # 🔘 Default/Secondary button style
    #
    # @param disabled [Boolean] Whether the button is disabled
    # @return [String] Tailwind CSS classes for default style
    def default_style(disabled: false)
      class_names(
        'text-slate-950 bg-slate-50 border-slate-200',
        'dark:text-slate-100 dark:bg-slate-800 dark:border-slate-600',
        {
          'hover:bg-slate-200 dark:hover:bg-slate-600' => !disabled
        }
      )
    end

    # 🔵 Primary button style
    #
    # @param disabled [Boolean] Whether the button is disabled
    # @return [String] Tailwind CSS classes for primary style
    def primary_style(disabled: false)
      class_names(
        'border-transparent text-white bg-primary-600 border-primary-600',
        'dark:bg-primary-700',
        {
          'hover:bg-primary-700 dark:hover:bg-primary-800' => !disabled
        }
      )
    end

    # 🔴 Danger/Destructive button style
    #
    # @param disabled [Boolean] Whether the button is disabled
    # @return [String] Tailwind CSS classes for danger style
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
