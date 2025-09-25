# frozen_string_literal: true

module Pathogen
  # Legacy icon constants for backward compatibility
  # TODO: Remove this file after migrating all usages to direct icon names
  module ICON
    # Icon definitions as constants (for backward compatibility)
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
    CLOCK = { name: 'clock', options: {} }.freeze
    CLIPBOARD = { name: 'clipboard-text', options: {} }.freeze
    DOTS_THREE_VERTICAL = { name: 'dots-three-outline-vertical', options: {} }.freeze
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
    TABLE = { name: 'table', options: {} }.freeze
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
    TOKEN = { name: 'poker-chip', options: { variant: :duotone } }.freeze
    # Special icons
    LOADING = { name: 'spinner-gap', options: { class: 'animate-spin' } }.freeze
  end
end

# Define global ICON constant for easier access
# This allows using ICON::ARROW_UP instead of Pathogen::ICON::ARROW_UP
ICON = Pathogen::ICON unless defined?(ICON)