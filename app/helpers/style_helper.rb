# frozen_string_literal: true

# Style-related helper methods for constructing inline CSS expressions used in
# view templates (e.g., dynamically sizing identifier columns).
module StyleHelper
  # ----------------------------------------------------------------------------
  # Constants
  # ----------------------------------------------------------------------------
  # Base number of spacing units (var(--spacing)) applied beside the character
  # length of an identifier column (PUID / UUID) when no checkbox is present.
  BASE_SPACING_MULTIPLIER = 6

  # Additional spacing units applied when a leading selection checkbox is
  # rendered. This usually aligns the text with other columns that also include
  # interactive controls.
  CHECKBOX_ADDITIONAL_SPACING = 3

  # Fixed pixel width reserved for the checkbox cell itself (including any
  # inherent left/right padding in the table layout).
  CHECKBOX_OFFSET_PX = 32

  # Standard canonical UUID length (8-4-4-4-12 including hyphens).
  UUID_LENGTH = 36

  # ----------------------------------------------------------------------------
  # Public Interface
  # ----------------------------------------------------------------------------
  # Build a CSS calc() expression representing the preferred width for a PUID
  # (Persistent Unique ID) column. The width is derived from the concrete
  # generated PUID length (stable pattern per class), augmented by a spacing
  # multiplier and—optionally—a fixed pixel offset when a leading checkbox is
  # displayed.
  #
  # @param object_class [Class] Class whose PUID pattern length we care about.
  # @param has_checkbox [Boolean] Whether a leading selection checkbox is shown.
  # @return [String] A CSS calc() expression, e.g. "calc(14ch + var(--spacing) * 9 + 32px)".
  def puid_width(object_class:, has_checkbox: false)
    puid_length = Irida::PersistentUniqueId.generate(object_class: object_class).length
    width_for(content_ch: puid_length, has_checkbox: has_checkbox)
  end

  # Build a CSS calc() expression for a UUID column. Mirrors the logic of
  # +puid_width+ but uses the canonical UUID length rather than computing it.
  #
  # @param has_checkbox [Boolean] Whether a leading selection checkbox is shown.
  # @return [String] A CSS calc() expression, e.g. "calc(36ch + var(--spacing) * 6)".
  def uuid_width(has_checkbox: false)
    width_for(content_ch: UUID_LENGTH, has_checkbox: has_checkbox)
  end

  private

  # Centralized width builder to keep the public helpers small and consistent.
  #
  # @param content_ch [Integer] Number of monospace character cells the value occupies.
  # @param has_checkbox [Boolean] Whether to account for the leading checkbox.
  # @return [String] CSS calc() expression.
  def width_for(content_ch:, has_checkbox: false)
    spacing_units = BASE_SPACING_MULTIPLIER + (has_checkbox ? CHECKBOX_ADDITIONAL_SPACING : 0)
    checkbox_offset = has_checkbox ? " + #{CHECKBOX_OFFSET_PX}px" : ''
    "calc(#{content_ch}ch + var(--spacing) * #{spacing_units}#{checkbox_offset})"
  end
end
