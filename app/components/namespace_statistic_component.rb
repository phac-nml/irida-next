# frozen_string_literal: true

# NamespaceStatisticComponent 📊 displays a single statistic item with an icon, label, and count.
# It uses unique HTML IDs for accessibility and testability.
class NamespaceStatisticComponent < Component
  # @!attribute [r] id_prefix
  #   @return [String] Prefix for unique HTML IDs.
  # @!attribute [r] icon_name
  #   @return [String] Heroicon name.
  # @!attribute [r] label
  #   @return [String] Label for the statistic (already translated).
  # @!attribute [r] count
  #   @return [Integer] Statistic value.
  # @!attribute [r] color_scheme
  #   @return [Symbol] Color scheme symbol (e.g., :blue, :teal).
  attr_reader :id_prefix, :icon_name, :label, :count, :color_scheme

  # Icon color variations 🎨.
  # Keys: color scheme symbols. Values: Tailwind CSS classes.
  ICON_COLOR_MAP = {
    blue: { icon_bg: 'bg-blue-100', dark_icon_bg: 'dark:bg-blue-700',
            icon_text: 'text-blue-700', dark_icon_text: 'dark:text-blue-200' },
    teal: { icon_bg: 'bg-teal-100', dark_icon_bg: 'dark:bg-teal-700',
            icon_text: 'text-teal-700', dark_icon_text: 'dark:text-teal-200' },
    indigo: { icon_bg: 'bg-indigo-100', dark_icon_bg: 'dark:bg-indigo-700',
              icon_text: 'text-indigo-700', dark_icon_text: 'dark:text-indigo-200' },
    fuchsia: { icon_bg: 'bg-fuchsia-100', dark_icon_bg: 'dark:bg-fuchsia-700',
               icon_text: 'text-fuchsia-700', dark_icon_text: 'dark:text-fuchsia-200' },
    amber: { icon_bg: 'bg-amber-100', dark_icon_bg: 'dark:bg-amber-700',
             icon_text: 'text-amber-700', dark_icon_text: 'dark:text-amber-200' }
  }.freeze

  # Default icon colors (slate-based) 🩶.
  DEFAULT_ICON_STYLES = {
    icon_bg: 'bg-slate-100',
    dark_icon_bg: 'dark:bg-slate-700',
    icon_text: 'text-slate-700',
    dark_icon_text: 'dark:text-slate-200'
  }.freeze

  # Initializes a new NamespaceStatisticComponent.
  #
  # @param id_prefix [String] Prefix for unique HTML IDs (e.g., "User Projects" becomes "user-projects").
  # @param icon_name [String] Heroicon name (e.g., 'users_solid').
  # @param label [String] Translated label for the statistic (e.g., t('projects.index.total_projects')).
  # @param count [Integer] Statistic value.
  # @param color_scheme [Symbol] Color scheme (e.g., :blue, :teal). Defaults to slate.
  def initialize(id_prefix:, icon_name:, label:, count:, color_scheme:)
    super
    @id_prefix = id_prefix.to_s.parameterize
    @icon_name = icon_name
    @label = label
    @count = count
    @color_scheme = color_scheme
  end

  # Defines Tailwind CSS classes based on `color_scheme` 💅.
  # Card: slate background. Icon: varies by `ICON_COLOR_MAP`.
  #
  # @return [Hash<Symbol, String>] Tailwind CSS classes for:
  #   - :bg, :dark_bg, :dark_border (card)
  #   - :icon_bg, :dark_icon_bg, :icon_text, :dark_icon_text (icon)
  def tailwind_colors
    card_base_styles = {
      bg: 'bg-slate-50',
      dark_bg: 'dark:bg-slate-900',
      dark_border: 'dark:border-slate-700'
    }

    current_icon_styles = ICON_COLOR_MAP.fetch(color_scheme, DEFAULT_ICON_STYLES)

    card_base_styles.merge(current_icon_styles)
  end

  # HTML ID for the small icon 🔍.
  # For ARIA or styling/scripting.
  # @return [String] HTML ID (e.g., "user-projects-icon-sm").
  def icon_id_sm
    "#{id_prefix}-icon-sm"
  end

  # HTML ID for the large icon 🔎.
  # For ARIA or styling/scripting.
  # @return [String] HTML ID (e.g., "user-projects-icon-lg").
  def icon_id_lg
    "#{id_prefix}-icon-lg"
  end

  # HTML ID for the unified icon 🔍.
  # For the simplified layout that works at all zoom levels.
  # @return [String] HTML ID (e.g., "user-projects-icon-unified").
  def icon_id_unified
    "#{id_prefix}-icon-unified"
  end

  # HTML ID for the large label 🏷️.
  # For ARIA (e.g., `aria-labelledby`) or styling/scripting.
  # @return [String] HTML ID (e.g., "user-projects-label-lg").
  def label_id_lg
    "#{id_prefix}-label-lg"
  end

  # HTML ID for the unified label 🏷️.
  # For the simplified layout that works at all zoom levels.
  # @return [String] HTML ID (e.g., "user-projects-label-unified").
  def label_id_unified
    "#{id_prefix}-label-unified"
  end
end
