# frozen_string_literal: true

module Layout
  class SidebarComponent < ViewComponent::Base
    renders_one :header, Sidebar::HeaderComponent
    renders_many :sections, Sidebar::SectionComponent
    renders_many :items, Sidebar::ItemComponent

    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end

    def renders?
      sections.any? || items.any?
    end
  end
end
