# frozen_string_literal: true

module Viral
  module Modal
    # Component to actual display the modal window.
    class WindowComponent < Viral::Component
      attr_reader :closable, :close_button_arguments, :title, :size

      renders_one :body
      renders_one :primary_action, lambda { |**system_arguments|
        Viral::ButtonComponent.new(type: :primary, **system_arguments)
      }
      renders_many :secondary_actions

      SIZE_DEFAULT = :default
      SIZE_MAPPINGS = {
        small: 'modal--size-sm',
        default: 'modal--size-md',
        large: 'modal--size-lg',
        extra_large: 'modal--size-xl'
      }.freeze

      def initialize(title:, closable: true, size: SIZE_DEFAULT)
        @closable = closable
        @size = SIZE_MAPPINGS[size]
        @title = title

        @close_button_arguments = {
          tag: 'button',
          type: 'button',
          data: { action: 'click->viral--modal-component#close' },
          classes: 'modal--dialog-close',
          aria: { label: t('components.modal.close') }
        }
      end

      def render_footer?
        primary_action.present? || secondary_actions.any?
      end
    end
  end
end
