# frozen_string_literal: true

# 🚀 ICONS: Centralized Icon Name Registry
#
# Standardizes icon usage across the UI for both Phosphor and Heroicons.
# Provides a unified interface for referencing icons by semantic names.
#
# Accessible globally. Use in ViewComponents, helpers, and Stimulus controllers.
#
# 💡 Add new icons as needed, using semantic names. Document all additions.
#
# @example Usage in a ViewComponent
#   render IconComponent.new(ICONS.project)
#
# @example Usage in a helper
#   ICONS[:alert]
#
# @see https://phosphoricons.com/ and https://heroicons.com/
#
module ICONS
  # :section: Phosphor Icons
  PHOSPHOR = {
    clipboard: [:clipboard, {}],
    export: [:export, {}],
    file: [:file, {}],
    files: [:files, {}],
    squares_four: [:'squares-four',  {}],
    list_bullets: [:'list-bullets',  {}],
    stack: [:stack,           {}],
    flask: [:flask,           {}],
    terminal_window: [:'terminal-window', {}],
    gear_six: [:'gear-six', {}],
    plus_circle: [:'plus-circle', {}],
    question: [:question, {}],
    sidebar: [:sidebar, {}],
    user_circle: [:user_circle, {}],
    users: [:users, {}],
    workflows: [:'terminal-window', {}] # NOTE: Duplicate of terminal_window above, kept for potential semantic difference
  }.freeze

  # :section: Heroicons
  HEROICONS = {
    beaker: [:beaker, { library: :heroicons, variant: :solid }]
  }.freeze

  # :section: Default Mappings
  DEFAULTS = {
    irida_logo: [:flask, { variant: :fill }],
    projects: PHOSPHOR[:stack],
    groups: PHOSPHOR[:squares_four],
    samples: PHOSPHOR[:flask],
    workflows: PHOSPHOR[:terminal_window],
    data_exports: PHOSPHOR[:export],
    settings: PHOSPHOR[:gear_six],
    user: PHOSPHOR[:user_circle],
    users: PHOSPHOR[:users]
  }.freeze

  # :section: Unified Lookup
  # Internal storage of raw definitions
  RAW_DEFINITIONS = PHOSPHOR.merge(HEROICONS).merge(DEFAULTS).freeze

  # Lookup by symbol or string, returns processed format [name, options_hash]
  #
  # @param key [Symbol, String] The key to look up.
  # @return [Array, nil] Icon definition `[name, merged_options]` or nil if not found.
  def self.[](key)
    RAW_DEFINITIONS[key.to_sym]
  end

  # Dot notation (e.g., ICONS.project), returns processed format [name, options_hash]
  #
  # @param method [Symbol] The method name corresponding to the icon key.
  # @return [Array, nil] Icon definition `[name, merged_options]` or nil if not found.
  def self.method_missing(method, *args, &)
    definition = RAW_DEFINITIONS[method]
    return definition if definition

    super
  end

  # Checks if a method corresponds to an icon key.
  #
  # @param method [Symbol] The method name to check.
  # @param include_private [Boolean] Whether to include private methods in the check.
  # @return [Boolean] True if the method corresponds to an icon key, false otherwise.
  def self.respond_to_missing?(method, include_private = false)
    RAW_DEFINITIONS.key?(method) || super
  end
end

# Helper for rendering icons defined in the ICONS registry.
module IconHelper
  # Renders an icon using its key from the ICONS registry.
  #
  # @param key [Symbol] The key of the icon in the ICONS registry (e.g., :irida_logo, :project).
  # @param options [Hash] Additional HTML options to pass to the underlying icon helper (e.g., class:, data:).
  #                       These options will be merged with the base options defined in ICONS.
  #                       Class attributes are intelligently merged.
  # @return [ActiveSupport::SafeBuffer, nil] The HTML safe string for the icon SVG, or nil if the key is not found.
  def render_icon(key, **options)
    name, base_options = ICONS[key]
    return nil unless name

    # Merge classes intelligently
    merged_classes = class_names(base_options[:class], options[:class])

    # Merge base options with provided options, giving priority to provided options for non-class keys
    final_options = base_options.except(:class).merge(options.except(:class))
    final_options[:class] = merged_classes if merged_classes.present?
    final_options[:'data-test-selector'] = name if Rails.env.test?

    # Call the underlying icon helper (assuming it's named `icon`)
    # Adjust if the actual helper used by the project (e.g., heroicon) is different.
    icon(name, **final_options)
  end
end
