# frozen_string_literal: true

module Viral
  # A component for displaying a dialog.
  class DialogComponent < Viral::Component
    attr_reader :open, :closable, :title

    renders_one :header, lambda { |title:|
      Viral::Dialog::HeaderComponent.new(title:, closable: @closable)
    }
    renders_many :sections, Viral::Dialog::SectionComponent
    renders_one :primary_action, lambda { |**system_arguments|
      Viral::ButtonComponent.new(state: :primary, **system_arguments)
    }
    renders_many :secondary_actions

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      small: 'dialog--size-sm max-w-md',
      default: 'dialog--size-md max-w-xl',
      large: 'dialog--size-lg max-w-3xl',
      extra_large: 'dialog--size-xl max-w-7xl'
    }.freeze

    renders_one :trigger

    def initialize(title: '', size: SIZE_DEFAULT, open: false, closable: true, **system_arguments)
      @title = title
      @open = open
      @closable = closable
      @system_arguments = system_arguments
      @system_arguments[:classes] = classes(size:)

      return if closable

      @system_arguments[:data] = {
        action: 'keydown.esc->viral--dialog#handleEsc'
      }
    end

    def classes(size:)
      "
        relative
        w-full
        p-0
        bg-white
        rounded-lg
        drop-shadow-md
        dark:bg-slate-800
        focus:outline-none
        backdrop:bg-slate-400/30
        backdrop:dark:bg-slate-900/40
        backdrop:backdrop-blur-sm
        #{SIZE_MAPPINGS[size]}
      "
    end

    def render_footer?
      primary_action.present? || secondary_actions.any?
    end
  end
end
