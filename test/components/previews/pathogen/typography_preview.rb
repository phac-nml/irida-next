# frozen_string_literal: true

module Pathogen
  # ViewComponent preview for demonstrating Pathogen Typography System
  # Showcases all typography components with examples, variants, and best practices
  class TypographyPreview < ViewComponent::Preview
    include Pathogen::ViewHelper

    # @!group Typography System

    # @label Overview
    # Complete overview of the typography system with all component types
    def overview; end

    # @label Headings
    # Semantic headings (h1-h6) with responsive sizing and color variants
    def headings; end

    # @label Body Text
    # Standard body text components for paragraphs and main content
    def body_text; end

    # @label Supporting Text
    # Captions, labels, and supporting text components
    def supporting_text; end

    # @label Special Components
    # Lead paragraphs, eyebrow text, code snippets, and lists
    def special_components; end

    # @label Dark Mode
    # Typography components in light and dark mode with color variants
    def dark_mode; end

    # @label Accessibility
    # Semantic HTML, ARIA patterns, and accessibility best practices
    def accessibility; end

    # @label Do's and Don'ts
    # Best practices and common mistakes when using typography components
    def dos_and_donts; end

    # @label In Context
    # Real-world examples showing typography components in actual page layouts
    def in_context; end

    # @label Presets
    # Pre-configured typography patterns for common UI scenarios (article, card, section, dialog, form)
    def presets; end
  end
end
