# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Viral::Component
    attr_reader :open, :modal_size, :title

    renders_one :header, Viral::Modal::HeaderComponent
    renders_many :sections, Viral::Modal::SectionComponent

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      small: 'modal--size-sm',
      default: 'modal--size-md',
      large: 'modal--size-lg',
      extra_large: 'modal--size-xl'
    }.freeze

    renders_one :trigger

    def initialize(title: '', size: SIZE_DEFAULT, open: false)
      @title = title
      @open = open
      @modal_size = SIZE_MAPPINGS[size]
    end
  end
end
