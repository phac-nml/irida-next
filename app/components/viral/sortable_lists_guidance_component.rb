# frozen_string_literal: true

module Viral
  # Renders an accessible guidance box explaining how a two-list sortable interface works.
  # Displays available/selected list descriptions with icons and keyboard shortcut help.
  #
  # @param title [String] heading text
  # @param instructions [String] general instructions
  # @param keyboard_help [String] keyboard shortcut help
  # @param available [Hash] keys: title, description, icon (default: :plus)
  # @param selected [Hash] keys: title, description, icon (default: :list_bullets)
  class SortableListsGuidanceComponent < Viral::Component
    attr_reader :title, :instructions, :keyboard_help, :available, :selected, :id_prefix

    def initialize(title:, instructions:, keyboard_help:, available:, selected:)
      @title = title
      @instructions = instructions
      @keyboard_help = keyboard_help
      @available = { icon: :plus }.merge(available)
      @selected = { icon: :list_bullets }.merge(selected)
      @id_prefix = "sortable-lists-guidance-#{SecureRandom.hex(4)}"
    end
  end
end
