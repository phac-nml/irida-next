# frozen_string_literal: true

module DropdownComponent
  class ItemComponent < Viral::Component
    def initialize(label, icon_name: nil, **_system_arguments)
      @label = label
      @icon = icon_name
    end
  end
end
