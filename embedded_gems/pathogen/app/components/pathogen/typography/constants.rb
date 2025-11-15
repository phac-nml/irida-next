# frozen_string_literal: true

module Pathogen
  module Typography
    # Constants for the Pathogen Typography System
    # Defines typography scale, font families, line heights, and color variants
    module Constants
      # Typography scale mapping pixel sizes to Tailwind classes
      # Based on a modular scale with ratio ~1.25
      TYPOGRAPHY_SCALE = {
        12 => 'text-xs',    # Eyebrow text
        14 => 'text-sm',    # Supporting text
        16 => 'text-base',  # Body text
        18 => 'text-lg',    # Callout text (emphasized paragraphs)
        20 => 'text-xl',    # Lead paragraphs
        25 => 'text-2xl',   # H6 / Mobile H5
        31 => 'text-3xl',   # H5 / Mobile H4 / Desktop H1
        39 => 'text-4xl',   # H4 / Mobile H3 / Desktop H2
        49 => 'text-5xl'    # H3 / Mobile H2 / Desktop H1
      }.freeze

      # Font family classes
      FONT_FAMILIES = {
        ui: 'font-sans',      # UI font stack (Inter, system fonts)
        mono: 'font-mono'      # Monospace for code
      }.freeze

      # Line height classes
      LINE_HEIGHTS = {
        heading: 'leading-tight',  # Tight for headings
        body: 'leading-normal',    # Normal for body text
        relaxed: 'leading-relaxed' # Relaxed for lead paragraphs
      }.freeze

      # Letter spacing classes
      LETTER_SPACING = {
        tight: 'tracking-tight',
        normal: 'tracking-normal',
        wide: 'tracking-wide',
        wider: 'tracking-wider',
        widest: 'tracking-widest'
      }.freeze

      # Responsive size mappings for headings
      # Format: { level => { mobile: 'class', desktop: 'class' } }
      RESPONSIVE_SIZES = {
        1 => { mobile: 'text-3xl', desktop: 'text-5xl' },  # 31px → 49px
        2 => { mobile: 'text-2xl', desktop: 'text-4xl' },  # 25px → 39px
        3 => { mobile: 'text-xl', desktop: 'text-3xl' },   # 20px → 31px
        4 => { mobile: 'text-lg', desktop: 'text-2xl' },   # 18px → 25px
        5 => { mobile: 'text-base', desktop: 'text-xl' },  # 16px → 20px
        6 => { mobile: 'text-sm', desktop: 'text-lg' }      # 14px → 18px
      }.freeze

      # Responsive size mappings for text components
      # Format: { component_name => { mobile: 'class', desktop: 'class' } }
      TEXT_RESPONSIVE_SIZES = {
        text: { mobile: 'text-sm', desktop: 'text-base' },         # 14px → 16px
        supporting: { mobile: 'text-xs', desktop: 'text-sm' },     # 12px → 14px
        lead: { mobile: 'text-lg', desktop: 'text-xl' },           # 18px → 20px
        callout: { mobile: 'text-base', desktop: 'text-lg' }       # 16px → 18px
      }.freeze

      # Color variants for typography components
      COLOR_VARIANTS = {
        default: 'text-slate-900 dark:text-white',
        muted: 'text-slate-500 dark:text-slate-400',
        subdued: 'text-slate-700 dark:text-slate-300',
        inverse: 'text-white dark:text-slate-900'
      }.freeze

      # Typography presets for common UI patterns
      # Each preset defines a configuration for HeadingGroup and related components
      PRESETS = {
        article: {
          heading_level: 1,
          heading_variant: :default,
          heading_responsive: true,
          eyebrow_variant: :muted,
          metadata_variant: :muted,
          spacing: :default
        },
        card: {
          heading_level: 3,
          heading_variant: :default,
          heading_responsive: false,
          eyebrow_variant: :muted,
          metadata_variant: :muted,
          spacing: :compact
        },
        section: {
          heading_level: 2,
          heading_variant: :default,
          heading_responsive: true,
          metadata_variant: :muted,
          spacing: :default
        },
        dialog: {
          heading_level: 2,
          heading_variant: :default,
          heading_responsive: false,
          spacing: :compact
        },
        form_section: {
          heading_level: 3,
          heading_variant: :default,
          heading_responsive: false,
          metadata_variant: :muted,
          spacing: :compact
        }
      }.freeze
    end
  end
end
