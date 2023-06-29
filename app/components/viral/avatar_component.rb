# frozen_string_literal: true

module Viral
  class AvatarComponent < Viral::Component
    attr_reader :initials, :size, :font_styles

    SIZE_DEFAULT = :medium
    SIZE_MAPPINGS = {
      small: 'w-8 h-8',
      medium: 'w-12 h-12',
      large: 'w-16 h-16'
    }.freeze

    def initialize(initials: nil, colour_string: nil, size: SIZE_DEFAULT, **system_arguments)
      @initials = initials
      @colours = generate_hsla_colour(colour_string || initials)
      @size = size
      @font_styles = if size == :small
                       'text-lg font-medium'
                     else
                       size == :medium ? 'text-2xl font-semibold' : 'text-5xl font-bold'
                     end
      @system_arguments = system_arguments
    end

    def generate_hsla_colour(name)
      h = name.hash.abs % 360
      { dark: "hsla(#{h}, 100%, 30%, .4)", light: "hsla(#{h}, 100%, 85%, .4)" }
    end

    def system_arguments
      @system_arguments.tap do |opts|
        opts[:tag] = :div
        opts[:role] = :img
        opts[:style] = "background-color: #{@colours[:light]}; border: 1px solid #{@colours[:dark]};"
        opts[:classes] = class_names(
          'avatar',
          SIZE_MAPPINGS[@size]
        )
      end
    end
  end
end
