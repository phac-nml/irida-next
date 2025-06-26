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

  # Initializes a new NamespaceStatisticComponent.
  #
  # @param id_prefix [String] Prefix for unique HTML IDs (e.g., "User Projects" becomes "user-projects").
  # @param icon_name [String] Heroicon name (e.g., 'users_solid').
  # @param label [String] Translated label for the statistic (e.g., t('projects.index.total_projects')).
  # @param count [Integer] Statistic value.
  # @param color_scheme [Symbol] Color scheme (e.g., :blue, :teal). Defaults to :default.
  def initialize(id_prefix:, icon_name:, label:, count:, color_scheme: :default)
    super
    @id_prefix = id_prefix.to_s.parameterize
    @icon_name = icon_name
    @label = label
    @count = count
    @color_scheme = color_scheme
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
