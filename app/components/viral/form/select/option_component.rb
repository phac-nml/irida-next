# frozen_string_literal: true

module Viral
  module Form
    module Select
      # Options for a select component
      class OptionComponent < ViewComponent::Base
        with_collection_parameter :option

        erb_template <<~ERB
          <% if @selected_value == @option[:value] %>
            <option value="<%= @option[:value] %>" selected>
          <% else %>
            <option value="<%= @option[:value] %>">
          <% end %>
            <%= @option[:label] %>
          </option>
        ERB

        def initialize(option:, selected_value: nil)
          @option = option
          @selected_value = selected_value
        end
      end
    end
  end
end
