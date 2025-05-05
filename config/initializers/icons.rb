# frozen_string_literal: true
# 🚀 ICONS: Centralized Icon Name Registry
#
# Standardizes icon usage across the UI for both Phosphor and Heroicons.
# Reference as: ICONS.project, ICONS[:user], etc.
#
# 💡 Add new icons as needed, using semantic names. Document all additions.
#
# Accessible globally. Use for ViewComponent, helpers, and Stimulus controllers.
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
    projects:    { library: :phosphor, name: :stack, variant: :duotone },
    groups:      { library: :phosphor, name: "squares-four", variant: :duotone },
    workflows:   { library: :phosphor, name: "terminal-window", variant: :duotone },
    data_exports: { library: :phosphor, name: :export, variant: :duotone },
    user:       { library: :phosphor, name: :user_circle, variant: :duotone },
    alert:      { library: :phosphor, name: :warning, variant: :duotone },
    # ...add more as needed
  }.freeze

  # :section: Heroicons
  HEROICONS = {
    search:     { library: :heroicons, name: :magnifying_glass, variant: :outline },
    menu:       { library: :heroicons, name: :bars_3, variant: :outline },
    close:      { library: :heroicons, name: :x_mark, variant: :solid },
    # ...add more as needed
  }.freeze

  # :section: Unified lookup
  ICONS = PHOSPHOR.merge(HEROICONS).freeze

  # Lookup by symbol or string
  # @param key [Symbol, String]
  # @return [Hash, nil]
  def self.[](key)
    ICONS[key.to_sym]
  end

  # Dot notation (ICONS.project)
  def self.method_missing(method, *args, &block)
    return ICONS[method] if ICONS.key?(method)
    super
  end

  def self.respond_to_missing?(method, include_private = false)
    ICONS.key?(method) || super
  end
end
