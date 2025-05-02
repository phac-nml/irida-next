# frozen_string_literal: true

module Viral
  module Pagy
    # Pagy pagination component
    class PaginationComponent < Viral::Component
      def initialize(pagy, data_string: 'data-turbo-action="replace"')
        @pagy = pagy
        @data_string = data_string
      end

      def render?
        @pagy.next || @pagy.prev
      end
    end
  end
end
