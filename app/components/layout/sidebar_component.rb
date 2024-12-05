# frozen_string_literal: true

module Layout
  # Sidebar component to for navigation
  class SidebarComponent < Component
    attr_reader :label, :tooltip

    renders_one :header, Sidebar::HeaderComponent
    renders_many :sections, Sidebar::SectionComponent
    renders_many :items, Sidebar::ItemComponent

    def initialize(label:, pipelines_enabled: true, **system_arguments)
      @label = label
      @tooltip = label
      @pipelines_enabled = pipelines_enabled
      @system_arguments = system_arguments
    end
  end
end
