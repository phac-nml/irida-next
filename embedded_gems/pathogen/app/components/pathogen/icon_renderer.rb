# frozen_string_literal: true

module Pathogen
  # IconRenderer handles HTML generation and cleanup for Pathogen::Icon.
  #
  # This class is responsible for building rails_icons options, applying styling,
  # and cleaning up invalid data attributes from the generated SVG HTML.
  class IconRenderer
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    attr_reader :icon_name, :color, :size, :variant, :rails_icons_options

    # Initialize the renderer with icon parameters
    #
    # @param icon_name [String] The normalized icon name
    # @param color [Symbol] The validated color
    # @param size [Symbol] The validated size
    # @param variant [String, Symbol, nil] Icon variant
    # @param rails_icons_options [Hash] Complete options for rails_icons
    def initialize(icon_name, color, size, variant, rails_icons_options)
      @icon_name = icon_name
      @color = color
      @size = size
      @variant = variant
      @rails_icons_options = rails_icons_options
    end

    # Build complete rails_icons options with styling applied
    #
    # @param variant [String, Symbol, nil] Icon variant
    # @param library [String, Symbol, nil] Icon library
    # @param additional_options [Hash] Additional options to merge
    # @return [Hash] Complete options hash for rails_icons
    def self.build_options(variant, library, additional_options)
      options = additional_options.dup

      options[:variant] = variant if variant
      options[:library] = library if library

      options
    end

    # Apply Pathogen styling classes to the options
    #
    # @param options [Hash] The options hash to modify
    # @param color [Symbol] The color variant
    # @param size [Symbol] The size variant
    # @param variant [String, Symbol, nil] The icon variant
    def self.apply_styling(options, color, size, variant)
      pathogen_classes = build_pathogen_classes(color, size, variant)
      options[:class] = combine_classes(pathogen_classes, options[:class])
    end

    # Remove invalid data attributes from rendered HTML
    #
    # rails_icons sometimes adds empty or invalid data attributes to SVG elements.
    # SVG elements don't support data attributes according to the SVG spec.
    #
    # @param html [String, ActiveSupport::SafeBuffer] The HTML to clean
    # @return [ActiveSupport::SafeBuffer] Cleaned HTML
    def self.clean_html(html)
      return html unless html.is_a?(String) || html.is_a?(ActiveSupport::SafeBuffer)

      raw_html = html.to_s
      clean_with_nokogiri(raw_html) || clean_with_regex(raw_html)
    end

    # Build Pathogen styling classes
    #
    # @param color [Symbol] The color variant
    # @param size [Symbol] The size variant
    # @param variant [String, Symbol, nil] The icon variant
    # @return [String] Combined CSS classes
    def self.build_pathogen_classes(color, size, variant)
      combine_classes(
        IconValidator::COLORS[color],
        IconValidator::SIZES[size],
        filled_variant_class(variant)
      )
    end

    # Combine CSS classes, filtering out nil and blank values
    #
    # @param classes [Array<String, nil>] CSS classes to combine
    # @return [String] Combined CSS class string
    def self.combine_classes(*classes)
      classes.compact_blank.join(' ').strip
    end

    # Add CSS class for filled variants to ensure they inherit color
    #
    # @param variant [String, Symbol, nil] The icon variant
    # @return [String, nil] CSS class or nil
    def self.filled_variant_class(variant)
      variant&.to_s == 'fill' ? 'fill-current' : nil
    end

    # Append the normalized icon name directly as a CSS class.
    # This prevents rendering an invalid `name-icon` attribute while preserving
    # the ability to target specific icons via CSS or tests.
    #
    # @param options [Hash] Options hash to mutate
    # @param icon_name [String] Normalized icon name (dashed)
    def self.append_icon_name_class(options, icon_name)
      return if icon_name.blank?

      existing_class = options[:class] || options['class']
      options[:class] = combine_classes(existing_class, "#{icon_name}-icon")
    end

    # Clean HTML using Nokogiri for reliable parsing
    #
    # @param raw_html [String] The raw HTML string
    # @return [ActiveSupport::SafeBuffer, nil] Cleaned HTML or nil on error
    def self.clean_with_nokogiri(raw_html)
      fragment = Nokogiri::HTML::DocumentFragment.parse(raw_html)
      remove_svg_data_attributes(fragment)
      ActiveSupport::SafeBuffer.new(fragment.to_html)
    rescue StandardError => e
      Rails.logger.debug { "[Pathogen::Icon] Nokogiri cleanup failed: #{e.message}" }
      nil
    end

    # Remove data attributes from SVG elements in the fragment
    #
    # @param fragment [Nokogiri::HTML::DocumentFragment] The parsed HTML fragment
    def self.remove_svg_data_attributes(fragment)
      fragment.css('svg').each do |svg|
        svg.remove_attribute('data') if svg.attribute('data')
      end
    end

    # Fallback HTML cleaning using regex when Nokogiri fails
    #
    # @param raw_html [String] The raw HTML string
    # @return [ActiveSupport::SafeBuffer] Cleaned HTML
    def self.clean_with_regex(raw_html)
      cleaned = raw_html.gsub(/(<svg\b[^>]*?)\sdata=""/i) { Regexp.last_match(1) }
                        .gsub(/(<svg\b[^>]*?)\sdata(?=\s|>)/i) { Regexp.last_match(1) }
      ActiveSupport::SafeBuffer.new(cleaned)
    end
  end
end
