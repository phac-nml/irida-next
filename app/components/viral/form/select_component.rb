# frozen_string_literal: true

module Viral
  module Form
    class SelectComponent < ViewComponent::Base
      attr_reader :label, :name

      def initialize(label:, name:)
        @label = label
        @name = name
      end
    end
  end
end
