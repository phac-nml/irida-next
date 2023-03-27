# frozen_string_literal: true

# Icon Component for icons
class IconComponent < BaseComponent
  def initialize(name:, **system_arguments)
    @source = heroicons_source(name)
    @system_arguments = system_arguments
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes]
    )
  end
end
