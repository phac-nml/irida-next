# frozen_string_literal: true

# Component for rendering a screen reader-only live region for dynamic status announcements.
#
# This component provides an accessible way to announce dynamic content changes to screen reader users
# through ARIA live regions. It's commonly used for selection status, form validation, and other
# dynamic updates that should be communicated to assistive technology users.
#
# @example Basic usage (selection status)
#   <%= render LiveRegionComponent.new %>
#
# @example Custom politeness level (for errors)
#   <%= render LiveRegionComponent.new(politeness: :assertive) %>
#
# @example Custom Stimulus target
#   <%= render LiveRegionComponent.new(target: "formStatus") %>
#
# @example With custom data attributes
#   <%= render LiveRegionComponent.new(controller: "selection", data: { custom_attr: "value" }) %>
class LiveRegionComponent < Component
  VALID_POLITENESS_LEVELS = %i[polite assertive off].freeze
  DEFAULT_POLITENESS = :polite
  DEFAULT_TARGET = 'status'

  # @param politeness [Symbol] ARIA live politeness level (:polite, :assertive, or :off)
  # @param target [String] Stimulus target name for controller integration
  # @param controller [String, nil] Stimulus controller name to attach to (optional)
  # @param atomic [Boolean] Whether the region should be treated as atomic (announced as a whole)
  # @param data [Hash] Additional data attributes to merge with auto-generated Stimulus attributes
  def initialize(politeness: DEFAULT_POLITENESS, target: DEFAULT_TARGET, controller: nil, atomic: false, data: {})
    @politeness = validate_politeness(politeness)
    @target = target
    @controller = controller
    @atomic = atomic
    @data = data
  end

  private

  # Politeness level for ARIA live region
  # @return [Symbol]
  attr_reader :politeness

  # Stimulus target name
  # @return [String]
  attr_reader :target

  # Stimulus controller name
  # @return [String, nil]
  attr_reader :controller

  # Whether the region should be atomic
  # @return [Boolean]
  attr_reader :atomic

  # Additional data attributes
  # @return [Hash]
  attr_reader :data

  # Validates and returns the politeness level
  # @param level [Symbol] The requested politeness level
  # @return [Symbol] Valid politeness level
  def validate_politeness(level)
    return DEFAULT_POLITENESS unless VALID_POLITENESS_LEVELS.include?(level)

    level
  end

  # Data attributes for Stimulus integration
  # @return [Hash]
  def data_attributes
    attrs = {}
    attrs[:"#{controller}-target"] = target if controller
    attrs.merge(@data)
  end
end
