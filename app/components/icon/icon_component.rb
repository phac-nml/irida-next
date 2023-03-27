# frozen_string_literal: true

# Icon Component for icons
module Icon
  class IconComponent < ViewComponent::Base
    include ViewHelper

    def initialize(name:)
      @source = heroicons_source(name)
    end
  end
end
