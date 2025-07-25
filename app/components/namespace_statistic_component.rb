# frozen_string_literal: true

# NamespaceStatisticComponent 📊 displays a single statistic item with an optional icon, label, and value.
# It uses unique HTML IDs for accessibility and testability.
class NamespaceStatisticComponent < Component
  # @param id_prefix [String] Prefix for unique HTML IDs (e.g., "group-created" becomes "group-created").
  # @param label [String] Translated label for the statistic (e.g., t('groups.show.information.created_on')).
  # @param value [Object] The value to display (can be a number, date, or string).
  # @param icon_name [String, nil] Optional icon name (e.g., 'calendar').
  # @param color_scheme [Symbol] Color scheme (e.g., :blue, :teal). Defaults to :slate.
  # @param bg_color [String] Optional custom background color class.
  # @param dark_bg_color [String] Optional custom dark mode background color class.
  def initialize(id_prefix:, label:, value:, icon_name: nil, color_scheme: :slate, bg_color: nil, dark_bg_color: nil, # rubocop:disable Metrics/ParameterLists
                 **args)
    @id_prefix = id_prefix.to_s.parameterize
    @icon_name = icon_name
    @label = label
    @value = value
    @color_scheme = color_scheme
    @bg_color = bg_color
    @dark_bg_color = dark_bg_color

    # Call super with any remaining arguments
    super(**args)
  end

  # For backward compatibility
  def count
    @value.is_a?(Numeric) ? @value : 0
  end

  # Generate a unique ID for this component instance
  def component_id
    @component_id ||= "ns-stat-#{@id_prefix}-#{SecureRandom.hex(4)}"
  end

  # Override the tailwind_colors method to handle our color scheme
  def tailwind_colors(color_scheme = nil)
    color_scheme ||= @color_scheme
    super
  end

  # Make these methods available to the template
  def template_assigns
    {
      id_prefix: @id_prefix,
      icon_name: @icon_name,
      label: @label,
      value: @value,
      color_scheme: @color_scheme,
      bg_color: @bg_color,
      dark_bg_color: @dark_bg_color,
      count: count
    }
  end
end
