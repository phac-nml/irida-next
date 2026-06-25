# frozen_string_literal: true

require 'pagy/toolbox/helpers/support/a_lambda'

module Viral
  module Pagy
    # Pagy pagination component
    class PaginationComponent < Viral::Component
      def initialize(pagy, autofocus_link: nil)
        @pagy = pagy
        @autofocus_link = autofocus_link
      end

      def render?
        @pagy.next || @pagy.previous
      end

      def before_render
        @autofocus_link = helpers.request&.query_parameters&.key?('page') || false if @autofocus_link.nil?
      end
    end
  end
end
