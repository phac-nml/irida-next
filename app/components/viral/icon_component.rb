# frozen_string_literal: true

module Viral
  class IconComponent < Viral::Component
    COLOR_DEFAULT = :default
    COLOR_MAPPINGS = {
      COLOR_DEFAULT => '',
      :base => 'Viral-Icon--colorBase',
      :subdued => 'Viral-Icon--colorSubdued',
      :critical => 'Viral-Icon--colorCritical',
      :warning => 'Viral-Icon--colorWarning',
      :success => 'Viral-Icon--colorSuccess',
      :primary => 'Viral-Icon--colorPrimary'
    }.freeze
    COLOR_OPTIONS = COLOR_MAPPINGS.keys

    def initialize(
      name: nil,
      color: COLOR_DEFAULT,
      **system_arguments
    )
      @source = name ? viral_icon_source(name) : nil

      @system_arguments = system_arguments
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        'Viral-Icon',
        COLOR_MAPPINGS[color]
      )
    end
  end
end
