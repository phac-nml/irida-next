# frozen_string_literal: true

module Layout
  # Sidebar component to for navigation
  class SidebarComponent < Component
    renders_one :header, Sidebar::HeaderComponent
    renders_many :sections, Sidebar::SectionComponent
    renders_many :items, Sidebar::ItemComponent

    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end
  end
end
