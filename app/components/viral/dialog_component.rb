# frozen_string_literal: true

module Viral
  # A component for displaying a dialog.
  class DialogComponent < Viral::Component
    attr_reader :open, :closable, :dialog_size, :title

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
      small: 'max-w-md',
      default: 'max-w-xl',
      large: 'max-w-3xl',
      extra_large: 'max-w-7xl'
    }.freeze

    renders_one :trigger

    def initialize(title: '', size: SIZE_DEFAULT, open: false, closable: true, **system_arguments)
      @title = title
      @open = open
      @closable = closable
      @dialog_size = SIZE_MAPPINGS[size]
      @system_arguments = system_arguments

      return if closable

      @system_arguments[:data] = {
        action: 'keydown.esc->viral--dialog#handleEsc'
      }
    end

    def render_footer?
      primary_action.present? || secondary_actions.any?
    end
  end
end
