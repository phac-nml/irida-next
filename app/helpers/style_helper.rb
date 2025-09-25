# frozen_string_literal: true

# Helper methods for generating reusable inline CSS values used across views.
module StyleHelper
  # Returns a CSS calc() string for the PUID column width.
  # The width is based on the generated PUID length, spacing, and optionally a checkbox offset.
  #
  # @param object_class [Class] the class used to compute PUID length
  # @param has_checkbox [Boolean] whether to include additional width for a leading checkbox
  # @return [String] CSS width expression, e.g. "calc(12ch + var(--spacing) * 3 + 24px)"
  def puid_width(object_class:, has_checkbox: false)
    puid_length = Irida::PersistentUniqueId.generate(object_class: object_class).length
    checkbox_offset = has_checkbox ? ' + 32px' : ''
    "calc(#{puid_length}ch + var(--spacing) * 9#{checkbox_offset})"
  end

  # Returns a CSS calc() string for the UUID column width.
  # The width is based on the standard UUID format length (36 characters), spacing, and optionally a checkbox offset.
  #
  # @param has_checkbox [Boolean] whether to include additional width for a leading checkbox
  # @return [String] CSS width expression, e.g. "calc(36ch + var(--spacing) * 3 + 24px)"
  def uuid_width(has_checkbox: false)
    uuid_length = 36 # Standard UUID format: 8-4-4-4-12 = 36 characters including hyphens
    checkbox_offset = has_checkbox ? ' + 32px' : ''
    "calc(#{uuid_length}ch + var(--spacing) * 9#{checkbox_offset})"
  end
end
