# frozen_string_literal: true

module Viral
  # This component is a container for the tabs.
  class TabsComponent < Viral::Component
    attr_reader :id, :label

    renders_many :tabs, Viral::Tabs::TabComponent
    renders_one :search_bar, SearchComponent
    renders_one :tab_content

    def initialize(id:, label:)
      @id = id
      @label = label
    end
  end
end
