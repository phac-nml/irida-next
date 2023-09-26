# frozen_string_literal: true

module Viral
  class TabsComponent < Viral::Component
    renders_many :tab, Viral::Tabs::TabComponent
  end
end
