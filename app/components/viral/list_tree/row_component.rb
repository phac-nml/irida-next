# frozen_string_literal: true

module Viral
  module ListTree
    class RowComponent < ViewComponent::Base
      attr_reader :group

      def initialize(group:)
        @group = group
      end
    end
  end
end
