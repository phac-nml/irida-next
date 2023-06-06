# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Viral::Component
    attr_reader :open

    renders_one :trigger
    renders_one :window, 'Viral::Modal::ContentComponent'

    def initialize(open: false)
      @open = open
    end
  end
end
