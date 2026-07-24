# frozen_string_literal: true

module Combobox
  module V1
    # Option row used by combobox slots.
    class OptionComponent < ::Component
      attr_reader :value, :label
      attr_accessor :id

      erb_template <<~ERB
        <%= tag.div(
          id: @id,
          role: "option",
          "data-value": @value,
          "data-label": @label,
          "aria-disabled": @disabled ? "true" : nil,
        ) do %>
          <%= content.presence || @label %>
        <% end %>
      ERB

      def initialize(value:, label:, disabled: false, id: nil)
        @value = value
        @label = label
        @disabled = disabled
        @id = id
      end
    end
  end
end
