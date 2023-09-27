# frozen_string_literal: true

module Viral
  # This component is a container for the tabs.
  class TabsComponent < Viral::Component
    attr_reader :id

    renders_many :tabs, Viral::Tabs::TabComponent
    renders_one :tab_content

    def initialize(id:)
      @id = id
    end
  end
end
