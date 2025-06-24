# frozen_string_literal: true

module Pathogen
  # Pathogen::Icon renders a Heroicon SVG with variant coloring and system arguments.
  #
  # @example Default usage
  #   = render Pathogen::Icon.new(:clipboard)
  #
  # @example With variant and custom classes
  #   = render Pathogen::Icon.new(:clipboard, variant: :primary, size: nil, class: "size-24")
  #
  class Icon < Pathogen::Component
    # Tailwind color variants for icon text color
    VARIANT_CLASSES = {
      default: 'text-slate-900 dark:text-slate-100',
      subdued: 'text-slate-400 dark:text-slate-500',
      primary: 'text-primary-600 dark:text-primary-500',
      success: 'text-green-600 dark:text-green-500',
      warning: 'text-yellow-600 dark:text-yellow-500',
      danger: 'text-red-600 dark:text-red-500'
    }.freeze

    SIZES = {
      sm: 'size-4',
      md: 'size-6',
      lg: 'size-8',
      xl: 'size-10'
    }.freeze

    # @param icon [Symbol, String] The icon name or key (must be valid in ICON constant)
    # @param variant [Symbol] The color variant (default, primary, etc.)
    # @param system_arguments [Hash] Additional HTML/system arguments
    def initialize(icon, variant: nil, size: nil, **system_arguments)
      @icon_name = icon
      @system_arguments = system_arguments
      @system_arguments[:class] = class_names(
        VARIANT_CLASSES[variant] => variant.present?,
        SIZES[size] => size.present?,
        @system_arguments[:class] => @system_arguments[:class].present?
      )
    end

    # Render the icon using the icon helper
    def call
      render_icon(@icon_name, **@system_arguments)
    end
  end
end
