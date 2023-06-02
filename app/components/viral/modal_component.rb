# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Viral::Component
    attr_reader :closable, :close_button_arguments, :title, :size

    renders_one :body
    renders_one :primary_action, lambda { |primary: true, **system_arguments|
      Viral::BaseComponent.new(tag: 'button', classes: 'btn btn-primary', **system_arguments)
    }

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      small: 'modal--size-sm',
      default: 'modal--size-md',
      large: 'modal--size-lg',
      extra_large: 'modal--size-xl'
    }.freeze

    def initialize(title:, closable: true, size: SIZE_DEFAULT)
      @title = title
      @closable = closable
      @size = SIZE_MAPPINGS[size]

      @close_button_arguments = {
        tag: 'button',
        type: 'button',
        data: { action: 'click->viral--modal-component#close' },
        classes: 'text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white',
        aria: { label: t('components.modal.close') }
      }
    end

    def render_footer?
      primary_action.present?
    end
  end
end
