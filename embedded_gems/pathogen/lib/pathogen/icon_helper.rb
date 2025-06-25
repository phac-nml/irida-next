# frozen_string_literal: true

module Pathogen
  # ICON: Centralized Icon Registry with Constants
  #
  # Provides a unified interface for referencing icons by semantic names as constants.
  # Available globally as ICON:: for convenience (e.g., ICON::ARROW_UP)
  #
  # @example Usage in a ViewComponent
  #   = render_icon(ICON::CLIPBOARD)
  #   = render_icon(ICON::IRIDA_LOGO, class: "h-6 w-6")
  #
  # @example Legacy usage (still supported)
  #   = render_icon(ICON::CLIPBOARD)
  #   = render_icon(ICON::IRIDA_LOGO, class: "h-6 w-6")
  #
  # @see https://phosphoricons.com/ and https://heroicons.com/
  #
  module ICON
    # Icon definitions as constants
    ARROW_UP = { name: 'arrow-up', options: {} }.freeze
    ARROW_DOWN = { name: 'arrow-down', options: {} }.freeze
    ARROW_RIGHT = { name: 'arrow-right', options: {} }.freeze
    ARROW_LEFT = { name: 'arrow-left', options: {} }.freeze
    BANK = { name: :bank, options: {} }.freeze
    CALENDAR_DOTS = { name: 'calendar-dots', options: {} }.freeze
    CARET_DOWN = { name: 'caret-down', options: {} }.freeze
    CARET_LEFT = { name: 'caret-left', options: {} }.freeze
    CARET_RIGHT = { name: 'caret-right', options: {} }.freeze
    CARET_UP = { name: 'caret-up', options: {} }.freeze
    CHECK = { name: 'check', options: {} }.freeze
    CHECK_CIRCLE = { name: 'check-circle', options: {} }.freeze
    CLIPBOARD = { name: 'clipboard-text', options: {} }.freeze
    DOWNLOAD = { name: 'download-simple', options: {} }.freeze
    EXPORT = { name: :export, options: {} }.freeze
    EYE = { name: 'eye', options: {} }.freeze
    EYE_SLASH = { name: 'eye-slash', options: {} }.freeze
    FILE = { name: :file, options: {} }.freeze
    FILE_TEXT = { name: 'file-text', options: {} }.freeze
    FILE_MAGNIFYING_GLASS = { name: 'file-magnifying-glass', options: {} }.freeze
    FILES = { name: :files, options: {} }.freeze
    FLASK = { name: :flask, options: {} }.freeze
    FOLDER_OPEN = { name: 'folder-open', options: {} }.freeze
    GEAR_SIX = { name: 'gear-six', options: {} }.freeze
    INFO = { name: 'info', options: {} }.freeze
    LIST = { name: :list, options: {} }.freeze
    LIST_BULLETS = { name: 'list-bullets', options: {} }.freeze
    LOCK_KEY = { name: 'lock-key', options: {} }.freeze
    MAGNIFYING_GLASS = { name: 'magnifying-glass', options: {} }.freeze
    PLUS = { name: 'plus', options: {} }.freeze
    PLUS_CIRCLE = { name: 'plus-circle', options: {} }.freeze
    QUESTION = { name: :question, options: {} }.freeze
    ROBOT = { name: 'robot', options: {} }.freeze
    ROCKET_LAUNCH = { name: 'rocket-launch', options: {} }.freeze
    SIDEBAR = { name: :sidebar, options: {} }.freeze
    SLIDERS_HORIZONTAL = { name: 'sliders-horizontal', options: {} }.freeze
    SQUARES_FOUR = { name: 'squares-four', options: {} }.freeze
    STACK = { name: :stack, options: {} }.freeze
    TERMINAL_WINDOW = { name: 'terminal-window', options: {} }.freeze
    TICKET = { name: :ticket, options: {} }.freeze
    TRANSLATE = { name: 'translate', options: {} }.freeze
    USER_CIRCLE = { name: 'user-circle', options: {} }.freeze
    USERS = { name: :users, options: {} }.freeze
    WARNING_CIRCLE = { name: 'warning-circle', options: {} }.freeze
    X = { name: :x, options: {} }.freeze
    X_CIRCLE = { name: 'x-circle', options: {} }.freeze
    # Heroicons
    BEAKER = { name: :beaker, options: { library: :heroicons } }.freeze
    # Named icons
    IRIDA_LOGO = { name: :beaker, options: { library: :heroicons } }.freeze
    DETAILS = { name: 'clipboard-text', options: {} }.freeze
    SAMPLES = { name: 'test-tube', options: {} }.freeze
    SETTINGS = { name: 'gear-six', options: {} }.freeze
    PROJECTS = { name: 'stack', options: {} }.freeze
    GROUPS = { name: 'squares-four', options: {} }.freeze
    WORKFLOWS = { name: 'terminal-window', options: {} }.freeze
    DATA_EXPORTS = { name: 'export', options: {} }.freeze
    # Special icons
    LOADING = { name: 'faded-spinner', options: { library: :animated } }.freeze

    # Optional: for backward compatibility, provide a lookup hash
    DEFINITIONS = constants.each_with_object({}) do |const, hash|
      hash[const.to_s.downcase.to_sym] = const_get(const)
    end.freeze

    # Lookup by symbol or string (legacy support)
    def self.[](key)
      DEFINITIONS[key.to_sym]
    end
  end

  # Helper for rendering icons defined in the ICON registry
  module IconHelper
    # Renders an icon using Rails Designer Icons
    #
    # @param key [Hash, Symbol] Either an ICON constant hash or a symbol key (legacy)
    # @param options [Hash] Additional options to merge with the icon's default options
    # @return [ActiveSupport::SafeBuffer, nil] The HTML for the icon or nil if not found
    #
    # @example Render using a constant
    #   render_icon(ICON::CLIPBOARD)
    #
    # @example Render with additional options
    #   render_icon(ICON::CLIPBOARD, class: "h-5 w-5 text-primary-600")
    #
    # @example Legacy usage with Pathogen namespace
    #   render_icon(ICON::CLIPBOARD)
    #
    # @example Render with a symbol (legacy)
    #   render_icon(:clipboard)
    def render_icon(key, **options)
      icon_def = resolve_icon_definition(key)
      return nil unless icon_def

      icon_name = icon_def[:name]
      final_options = prepare_icon_options(icon_def, options, key)
      icon(icon_name, **final_options)
    end

    private

    # Resolves the icon definition from a constant hash or symbol
    def resolve_icon_definition(key)
      if key.is_a?(Hash) && key[:name]
        key
      elsif key.is_a?(Symbol) || key.is_a?(String)
        ICON[key]
      end
    end

    # Prepares the final options hash for the icon
    #
    # @param icon_def [Hash] The icon definition
    # @param user_options [Hash] User-provided options
    # @param key [Symbol, Hash] The original key for test selector
    # @return [Hash] The final options hash
    def prepare_icon_options(icon_def, user_options, key)
      base_options = icon_def[:options] || {}
      final_options = merge_icon_options(base_options, user_options)
      merged_class = merge_icon_classes(base_options[:class], user_options[:class])
      final_options[:class] = merged_class if merged_class.present?
      final_options['data-test-selector'] = build_test_selector(key) if Rails.env.test?
      # Ensure aria-hidden is true unless explicitly set
      unless final_options.key?('aria-hidden') || final_options.key?(:'aria-hidden')
        final_options['aria-hidden'] =
          true
      end
      final_options
    end

    # Extracted: Merge icon options except :class
    def merge_icon_options(base_options, user_options)
      base_options.except(:class).merge(user_options.except(:class))
    end

    # Extracted: Merge icon classes
    def merge_icon_classes(base_class, user_class)
      class_names(base_class, user_class)
    end

    # Extracted: Build test selector value
    def build_test_selector(key)
      if key.is_a?(Hash)
        const_name = ICON.constants.find { |c| ICON.const_get(c) == key }
        const_name ? const_name.to_s : key[:name].to_s
      elsif key.respond_to?(:to_s)
        key.to_s
      end
    end
  end
end

# Define global ICON constant for easier access
# This allows using ICON::ARROW_UP instead of Pathogen::ICON::ARROW_UP
ICON = Pathogen::ICON unless defined?(ICON)
