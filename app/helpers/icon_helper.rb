# frozen_string_literal: true

# Helper for rendering icons defined in the ICONS initializer.
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

    # Call the underlying icon helper (assuming it's named `icon`)
    # Adjust if the actual helper used by the project (e.g., heroicon) is different.
    icon(name, **final_options)
  end
end
