# frozen_string_literal: true

module Combobox
  module V1
    # Option row used by combobox slots.
    class OptionComponent < ::Component
      attr_reader :value, :label

      erb_template <<~ERB
        <%= tag.div(
          role: "option",
          "data-value": @value,
          "data-label": @label,
          "aria-disabled": @disabled ? "true" : nil,
        ) do %>
          <%= content.presence || @label %>
        <% end %>
      ERB

      def initialize(value:, label:, disabled: false)
        @value = value
        @label = label
        @disabled = disabled
      end
    end
  end
end
