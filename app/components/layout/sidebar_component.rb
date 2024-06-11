# frozen_string_literal: true

module Layout
  # Sidebar component to for navigation
  class SidebarComponent < Component
    attr_reader :label, :icon_name, :tooltip

    renders_one :header, Sidebar::HeaderComponent
    renders_many :sections, Sidebar::SectionComponent
    renders_many :items, Sidebar::ItemComponent

    def initialize(label:, icon_name:, pipelines_enabled:, **system_arguments)
      @label = label
      @tooltip = label
      @icon_name = icon_name
      @pipelines_enabled = pipelines_enabled
      @system_arguments = system_arguments
    end
  end
end
