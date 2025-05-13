# frozen_string_literal: true

# NamespaceStatisticComponent is a ViewComponent responsible for rendering a
# single statistic item, typically used within a dashboard or a summary section.
# It displays an icon, a label (derived from a translation key), and a count,
# styled with a configurable color scheme.
#
# The component generates unique HTML IDs for its elements based on the `id_prefix`
# to ensure accessibility and testability.
class NamespaceStatisticComponent < Component
  # @!attribute [r] id_prefix
  #   @return [String] The parameterized prefix used for generating unique HTML IDs.
  # @!attribute [r] icon_name
  #   @return [String] The name of the Heroicon to be displayed.
  # @!attribute [r] label_key
  #   @return [String] The I18n translation key for the statistic's label.
  # @!attribute [r] count
  #   @return [Integer] The numerical value of the statistic.
  # @!attribute [r] color_scheme
  #   @return [Symbol] The symbol representing the color scheme to apply (e.g., :blue, :teal).
  attr_reader :id_prefix, :icon_name, :label_key, :count, :color_scheme

  # Initializes a new NamespaceStatisticComponent.
  #
  # @param id_prefix [String] A string prefix used to generate unique HTML IDs for accessibility
  #                           and targeting. It will be parameterized (e.g., "User Projects" becomes "user-projects").
  # @param icon_name [String] The name of the Heroicon to display (e.g., 'users_solid').
  # @param label_key [String] The I18n translation key for the statistic's label
  #                           (e.g., 'projects.index.total_projects').
  # @param count [Integer] The numerical value of the statistic to display.
  # @param color_scheme [Symbol] A symbol indicating the color scheme for the component.
  #                             Supported schemes include :blue, :teal, :indigo, :fuchsia, :amber.
  #                             Defaults to a slate-based scheme if an unsupported symbol is provided.
  def initialize(id_prefix:, icon_name:, label_key:, count:, color_scheme:)
    super
    @id_prefix = id_prefix.to_s.parameterize
    @icon_name = icon_name
    @label_key = label_key
    @count = count
    @color_scheme = color_scheme
  end

  # Defines the Tailwind CSS classes for the component based on the `color_scheme`.
  # The card itself consistently uses a slate background, while the icon's colors vary.
  #
  # @return [Hash<Symbol, String>] A hash containing Tailwind CSS class strings for:
  #   - :bg (background of the card)
  #   - :dark_bg (dark mode background of the card)
  #   - :dark_border (dark mode border of the card)
  #   - :icon_bg (background of the icon container)
  #   - :dark_icon_bg (dark mode background of the icon container)
  #   - :icon_text (text color of the icon)
  #   - :dark_icon_text (dark mode text color of the icon)
  def tailwind_colors
    card_base_styles = {
      bg: 'bg-slate-50',
      dark_bg: 'dark:bg-slate-900',
      dark_border: 'dark:border-slate-700'
    }

    # Defines color variations for the icon part of the statistic.
    # Keys are color scheme symbols, values are hashes of Tailwind classes.
    icon_color_map = {
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
    }

    # Default icon colors (slate-based) if the scheme is not found or is explicitly :slate.
    default_icon_styles = {
      icon_bg: 'bg-slate-100',
      dark_icon_bg: 'dark:bg-slate-700',
      icon_text: 'text-slate-700',
      dark_icon_text: 'dark:text-slate-200'
    }

    current_icon_styles = icon_color_map.fetch(color_scheme, default_icon_styles)

    card_base_styles.merge(current_icon_styles)
  end

  # Generates a unique HTML ID for the small icon element.
  # Used for ARIA attributes or specific styling/scripting if needed.
  # @return [String] The HTML ID string (e.g., "user-projects-icon-sm").
  def icon_id_sm
    "#{id_prefix}-icon-sm"
  end

  # Generates a unique HTML ID for the large icon element.
  # Used for ARIA attributes or specific styling/scripting if needed.
  # @return [String] The HTML ID string (e.g., "user-projects-icon-lg").
  def icon_id_lg
    "#{id_prefix}-icon-lg"
  end

  # Generates a unique HTML ID for the large label element.
  # Used for ARIA attributes (e.g., `aria-labelledby`) or specific styling/scripting.
  # @return [String] The HTML ID string (e.g., "user-projects-label-lg").
  def label_id_lg
    "#{id_prefix}-label-lg"
  end
end
