# frozen_string_literal: true

require 'pagy/toolbox/helpers/support/a_lambda'

module Viral
  module Pagy
    # Pagy pagination component
    class PaginationComponent < Viral::Component
      def initialize(pagy)
        @pagy = pagy
      end

      def render?
        @pagy.next || @pagy.previous
      end
    end
  end
end
