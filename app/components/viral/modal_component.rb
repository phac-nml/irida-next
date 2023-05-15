# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Component
    attr_reader :title

    renders_one :body

    def initialize(title:)
      @title = title
    end
  end
end
