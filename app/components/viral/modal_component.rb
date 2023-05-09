# frozen_string_literal: true

module Viral
  # A component for displaying a modal.
  class ModalComponent < Component
    include Turbo::FramesHelper
    attr_reader :title

    def initialize(title:)
      @title = title
    end
  end
end
