# frozen_string_literal: true

module Viral
  # UI Icon Component
  class IconComponent < Viral::Component
    attr_reader :source

    COLOR_DEFAULT = :default
    COLOR_MAPPINGS = {
      COLOR_DEFAULT => '',
      :base => 'viral-icon--colorBase',
      :subdued => 'viral-icon--colorSubdued',
      :critical => 'viral-icon--colorCritical',
      :warning => 'viral-icon--colorWarning',
      :success => 'viral-icon--colorSuccess',
      :primary => 'viral-icon--colorPrimary'
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
        'viral-icon',
        COLOR_MAPPINGS[color]
      )
    end
  end
end
