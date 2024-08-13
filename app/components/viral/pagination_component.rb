# frozen_string_literal: true

module Viral
  # Pagy pagination component
  class PaginationComponent < Component
    def initialize(pagy:)
      @pagy = pagy
    end
  end
end
