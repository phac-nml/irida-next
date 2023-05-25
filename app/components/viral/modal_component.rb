# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Component
    attr_reader :title, :size, :label

    renders_one :body

    SIZE_DEFAULT = :default
    SIZE_MAPPINGS = {
      small: 'max-w-md',
      default: 'max-w-lg',
      large: 'max-w-4xl',
      extra_large: 'max-w-7xl'
    }.freeze

    def initialize(title:, size: SIZE_DEFAULT, label: nil)
      @title = title
      @size = SIZE_MAPPINGS[size]
      @label = label
    end
  end
end
