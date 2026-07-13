# frozen_string_literal: true

module Viral
  module Pagy
    # FullComponent is a component that renders the full pagy pagination
    # including the limit and pagination components.
    class FullComponent < Viral::Component
      def initialize(pagy, item:, params: {})
        @pagy = pagy
        @item = item
        @params = params
      end

      private

      attr_reader :pagy, :item
    end
  end
end
