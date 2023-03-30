# frozen_string_literal: true

# Icon Component for icons
class IconComponent < Component
  def initialize(name:, classes: nil)
    @source = heroicons_source(name, classes)
  end
end
