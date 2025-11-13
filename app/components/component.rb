# frozen_string_literal: true

# Component class
class Component < ViewComponent::Base
  attr_reader :system_arguments

  include ViewHelper
  include ClassNameHelper
  include Pathogen::ViewHelper
  include ActionView::Helpers::TranslationHelper

  delegate :locale, to: :I18n

  # Icon color variations 🎨.
  # Keys: color scheme symbols. Values: Tailwind CSS classes.
  ICON_COLOR_MAP = {
    blue: { icon_bg: 'bg-blue-100', dark_icon_bg: 'dark:bg-blue-700',
            icon_text: 'text-blue-700', dark_icon_text: 'dark:text-blue-200' },
    teal: { icon_bg: 'bg-teal-100', dark_icon_bg: 'dark:bg-teal-700',
            icon_text: 'text-teal-700', dark_icon_text: 'dark:text-teal-200' },
    indigo: { icon_bg: 'bg-indigo-100', dark_icon_bg: 'dark:bg-indigo-700',
              icon_text: 'text-indigo-700', dark_icon_text: 'dark:text-indigo-200' },
    fuchsia: { icon_bg: 'bg-fuchsia-100', dark_icon_bg: 'dark:bg-fuchsia-700',
               icon_text: 'text-fuchsia-700', dark_icon_text: 'dark:text-fuchsia-200' },
    amber: { icon_bg: 'bg-amber-100', dark_icon_bg: 'dark:bg-amber-700',
             icon_text: 'text-amber-700', dark_icon_text: 'dark:text-amber-200' }
  }.freeze

  # Default icon colors (slate-based) 🩶.
  DEFAULT_ICON_STYLES = {
    icon_bg: 'bg-slate-100',
    dark_icon_bg: 'dark:bg-slate-700',
    icon_text: 'text-slate-700',
    dark_icon_text: 'dark:text-slate-200'
  }.freeze

  # Defines Tailwind CSS classes based on `color_scheme` 💅.
  # Card: slate background. Icon: varies by `ICON_COLOR_MAP`.
  #
  # @param color_scheme [Symbol, nil] Color scheme symbol (e.g., :blue, :teal). Optional.
  # @return [Hash<Symbol, String>] Tailwind CSS classes for:
  #   - :bg, :dark_bg, :dark_border (card)
  #   - :icon_bg, :dark_icon_bg, :icon_text, :dark_icon_text (icon)
  def tailwind_colors(color_scheme = nil)
    card_base_styles = {
      bg: 'bg-slate-50',
      dark_bg: 'dark:bg-slate-900',
      dark_border: 'dark:border-slate-700'
    }
    current_icon_styles = color_scheme ? ICON_COLOR_MAP.fetch(color_scheme, DEFAULT_ICON_STYLES) : {}
    card_base_styles.merge(current_icon_styles)
  end
end
