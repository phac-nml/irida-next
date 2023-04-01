# frozen_string_literal: true

module Sidebar
  # Aside navigation component
  # @example
  #  <%= render Sidebar::SidebarComponent.new do |sidebar| %>
  #   <%= sidebar.with_header(label: "Home", url: root_url, icon: "home") %>
  #   <%= sidebar.with_section do |section| %>
  #    <%= section.with_item(label: "Dashboard", url: dashboard_url, icon: "dashboard") %>
  #    <%= section.with_item(label: "Settings", url: settings_url, icon: "settings") %>
  #   <% end %>
  #  <% end %>
  class SidebarComponent < Component
    renders_one :header, Navigation::HeaderComponent
    renders_many :sections, Navigation::SectionComponent
    renders_many :items, Navigation::ItemComponent

    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end
  end
end
