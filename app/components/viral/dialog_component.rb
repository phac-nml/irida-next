# frozen_string_literal: true

module Viral
  # A component for displaying a dialog.
  class DialogComponent < Viral::Component
    attr_reader :open, :dialog_size, :title

    renders_one :header, Viral::Dialog::HeaderComponent
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

    def initialize(title: '', size: SIZE_DEFAULT, open: false, **system_arguments)
      @title = title
      @open = open
      @dialog_size = SIZE_MAPPINGS[size]
      @system_arguments = system_arguments
    end

    def render_footer?
      primary_action.present? || secondary_actions.any?
    end
  end
end
