# frozen_string_literal: true

module Viral
  # A component for displaying a dialog.
  class DialogComponent < Viral::Component
    attr_reader :id, :open, :closable, :dialog_size, :title, :header_system_arguments

    renders_one :header, lambda { |title:|
      Viral::Dialog::HeaderComponent.new(title:, closable: @closable, **header_system_arguments)
    }
    renders_many :sections, Viral::Dialog::SectionComponent
    renders_one :primary_action, lambda { |**system_arguments|
      Viral::ButtonComponent.new(state: :primary, **system_arguments)
    }
    renders_many :secondary_actions

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      small: 'dialog--size-sm',
      default: 'dialog--size-md',
      large: 'dialog--size-lg',
      extra_large: 'dialog--size-xl'
    }.freeze

    renders_one :trigger

    def initialize(id: 'dialog', title: '', size: SIZE_DEFAULT, open: false, closable: true, header_system_arguments: {}, **system_arguments) # rubocop:disable Metrics/ParameterLists,Layout/LineLength
      @id = id
      @title = title
      @open = open
      @closable = closable
      @dialog_size = SIZE_MAPPINGS[size]
      @header_system_arguments = header_system_arguments
      @system_arguments = system_arguments

      @system_arguments[:data].merge!({ 'viral--dialog-target' => 'dialog' })

      return if closable

      @system_arguments[:data].merge!({
                                        action: 'keydown.esc->viral--dialog#handleEsc'
                                      })
    end

    def render_footer?
      primary_action.present? || secondary_actions.any?
    end
  end
end
