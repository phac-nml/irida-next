# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy pagination component
    class PaginationComponent < Viral::Component
      def initialize(pagy)
        @pagy = pagy
      end

      def render?
        @pagy.next || @pagy.prev
      end
    end
  end
end
