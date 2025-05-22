# frozen_string_literal: true

# ICONS: Centralized Icon Registry
#
# A simplified, elegant approach to icon management using Rails Designer Icons.
# Provides a unified interface for referencing icons by semantic names.
#
# @example Usage in a ViewComponent
#   = render_icon(:clipboard)
#   = render_icon(:irida_logo, class: "h-6 w-6")
#
# @example Usage with dot notation
#   = render_icon(ICONS.clipboard)
#
# @see https://phosphoricons.com/ and https://heroicons.com/
#
module ICONS
  # Icon definitions with semantic names mapping to actual icon names and default options
  #
  # Format:
  # semantic_name: {
  #   name: 'actual-icon-name',
  #   options: {
  #     library: :phosphor|:heroicons,
  #     variant: :outline|:solid|:duotone, etc.
  #   }
  # }
  #
  # Default library is :phosphor and default variant is :regular unless specified
  DEFINITIONS = {
    # Phosphor Icons (default library)
    clipboard: { name: 'clipboard-text', options: {} },
    caret_down: { name: 'caret-down', options: {} },
    caret_up: { name: 'caret-up', options: {} },
    export: { name: :export, options: {} },
    file: { name: :file, options: {} },
    files: { name: :files, options: {} },
    squares_four: { name: 'squares-four', options: {} },
    list_bullets: { name: 'list-bullets', options: {} },
    lock_key: { name: 'lock-key', options: {} },
    stack: { name: :stack, options: {} },
    flask: { name: :flask, options: {} },
    terminal_window: { name: 'terminal-window', options: {} },
    gear_six: { name: 'gear-six', options: {} },
    plus_circle: { name: 'plus-circle', options: {} },
    question: { name: :question, options: {} },
    sidebar: { name: :sidebar, options: {} },
    sliders_horizontal: { name: 'sliders-horizontal', options: {} },
    ticket: { name: :ticket, options: {} },
    user_circle: { name: 'user-circle', options: {} },
    users: { name: :users, options: {} },
    bank: { name: :bank, options: {} },

    # Heroicons
    beaker: { name: :beaker, options: { library: :heroicons } },

    # Named icons
    irida_logo: { name: :beaker, options: { library: :heroicons } },
    details: { name: 'clipboard-text', options: {} },
    samples: { name: :flask, options: {} },
    settings: { name: 'gear-six', options: {} },
    projects: { name: 'stack', options: {} },
    groups: { name: 'squares-four', options: {} },
    workflows: { name: 'terminal-window', options: {} },
    data_exports: { name: 'export', options: {} }

  }.freeze

  # Lookup by symbol or string
  #
  # @param key [Symbol, String] The icon key to look up
  # @return [Hash, nil] Icon definition or nil if not found
  def self.[](key)
    DEFINITIONS[key.to_sym]
  end

  # Enable dot notation access (e.g., ICONS.clipboard)
  #
  # @param method [Symbol] The method name corresponding to the icon key
  # @return [Hash, nil] Icon definition or nil if not found
  def self.method_missing(method, *args, &)
    DEFINITIONS[method] || super
  end

  # Support respond_to? for dot notation
  #
  # @param method [Symbol] The method name to check
  # @param include_private [Boolean] Whether to include private methods
  # @return [Boolean] True if the method corresponds to an icon key
  def self.respond_to_missing?(method, include_private = false)
    DEFINITIONS.key?(method) || super
  end
end

# Helper for rendering icons defined in the ICONS registry
module IconHelper
  # Renders an icon using Rails Designer Icons
  #
  # @param key [Symbol, Hash] Either a symbol key from ICONS registry or a direct icon definition hash
  # @param options [Hash] Additional options to merge with the icon's default options
  # @return [ActiveSupport::SafeBuffer, nil] The HTML for the icon or nil if not found
  #
  # @example Render using a key
  #   render_icon(:clipboard)
  #
  # @example Render with additional options
  #   render_icon(:clipboard, class: "h-5 w-5 text-primary-600")
  #
  # @example Render with a direct icon definition
  #   render_icon(ICONS.clipboard, variant: :duotone)
  def render_icon(key, **options)
    # Handle both symbol keys and direct icon definition hashes
    icon_def = resolve_icon_definition(key)
    return nil unless icon_def

    # Extract the icon name and prepare final options
    icon_name = icon_def[:name]
    final_options = prepare_icon_options(icon_def, options, key)

    # Call the Rails Designer Icons helper
    icon(icon_name, **final_options)
  end

  private

  # Resolves the icon definition from a key or hash
  #
  # @param key [Symbol, Hash] Either a symbol key from ICONS registry or a direct icon definition hash
  # @return [Hash, nil] The icon definition or nil if not found
  def resolve_icon_definition(key)
    key.is_a?(Hash) ? key : ICONS[key]
  end

  # Prepares the final options hash for the icon
  #
  # @param icon_def [Hash] The icon definition
  # @param user_options [Hash] User-provided options
  # @param key [Symbol, Hash] The original key for test selector
  # @return [Hash] The final options hash
  def prepare_icon_options(icon_def, user_options, key)
    base_options = icon_def[:options] || {}

    # Merge options, with user options taking precedence
    final_options = base_options.except(:class).merge(user_options.except(:class))

    # Intelligently merge classes
    merged_class = class_names(base_options[:class], user_options[:class])
    final_options[:class] = merged_class if merged_class.present?

    # Add test selector in test environment
    final_options['data-test-selector'] = key.to_s if Rails.env.test? && key.respond_to?(:to_s)

    final_options
  end
end
