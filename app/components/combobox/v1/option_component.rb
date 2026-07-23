# frozen_string_literal: true

module Combobox
  module V1
    # Option row used by combobox slots.
    class OptionComponent < ::Component
      erb_template <<~ERB
        <%= tag.div(
          role: "option",
          "data-value": @value,
          "data-label": @label,
          "aria-disabled": @disabled ? "true" : nil,
        ) do %>
          <%= content.presence %>
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
