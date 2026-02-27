# frozen_string_literal: true

module Viral
  module Dropdown
    module V1
      # 🚀 DropdownComponent: Professional, idiomatic dropdown for Viral UI
      #
      # Renders a dropdown menu with support for:
      #   - Custom label, icon, caret, and tooltip
      #   - Click or hover trigger
      #   - Action button mode
      #   - Accessibility (aria-label, aria-haspopup, etc.)
      #   - Custom styles and system arguments
      #   - Positions the dropdown using Popper.js with configurable distance and skidding
      #
      # 📝 Usage:
      #   <%= render Viral::Dropdown::V1::Component.new(label: "Menu", icon: :dots, tooltip: "More actions")
      #   do |dropdown| %>
      #     <%= dropdown.item ... %>
      #   <% end %>
      #
      class Component < Viral::Dropdown::BaseComponent
        private

        # 🏗️ Build data attributes for the dropdown trigger
        def build_data_attributes
          data = { 'viral--dropdown-target': 'trigger' }
          return data unless @action_link

          data.merge(
            turbo_stream: true,
            controller: 'action-button',
            action_link_required_value: @action_link_value
          )
        end
      end
    end
  end
end
