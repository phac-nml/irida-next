# frozen_string_literal: true

module Pathogen
  # Simple helper for rendering icons with backward compatibility
  module IconHelper
    # Renders an icon using rails_icons with backward compatibility support
    #
    # @param icon_name_or_hash [String, Symbol, Hash] Icon name or legacy ICON hash
    # @param options [Hash] Additional options for rails_icons
    # @return [ActiveSupport::SafeBuffer, nil] The HTML for the icon
    #
    # @example Direct usage (recommended)
    #   render_icon("clipboard-text")
    #   render_icon(:arrow_up, color: :primary)
    #
    # @example Legacy hash usage (backward compatibility)
    #   render_icon({ name: "clipboard-text", options: {} })
    def render_icon(icon_name_or_hash, **options)
      # Handle legacy hash format for backward compatibility
      if icon_name_or_hash.is_a?(Hash) && icon_name_or_hash[:name]
        legacy_options = icon_name_or_hash[:options] || {}
        icon_name = icon_name_or_hash[:name]

        # Merge classes properly
        if legacy_options[:class] && options[:class]
          merged_class = "#{legacy_options[:class]} #{options[:class]}"
          final_options = legacy_options.merge(options).merge(class: merged_class)
        else
          final_options = legacy_options.merge(options)
        end
      else
        icon_name = icon_name_or_hash
        final_options = options
      end

      # Ensure aria-hidden is set unless explicitly provided
      final_options['aria-hidden'] = true unless final_options.key?('aria-hidden') || final_options.key?(:'aria-hidden')

      # Add icon-specific class for backward compatibility (only in non-production)
      unless Rails.env.production?
        icon_class = "#{icon_name.to_s.tr('_', '-')}-icon"
        existing_class = final_options[:class] || final_options['class'] || ''
        final_options[:class] = "#{existing_class} #{icon_class}".strip
      end

      icon(icon_name, **final_options)
    end
  end
end
