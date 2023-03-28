# frozen_string_literal: true

module Navigation
  class NavigationComponent < Component
    renders_many :sections, Navigation::SectionComponent
    renders_many :items, Navigation::ItemComponent

    def initialize(**system_arguments)
      @system_arguments = system_arguments
    end

    def renders?
      sections.any? || items.any?
    end
  end
end
