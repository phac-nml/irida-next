# frozen_string_literal: true

module Viral
  # Avatar component to display on items first letter
  class AvatarComponent < Viral::Component
    attr_reader :initials, :size, :font_styles, :url

    SIZE_DEFAULT = :medium
    SIZE_MAPPINGS = {
      xs: 'w-6 h-6',
      small: 'w-8 h-8',
      medium: 'w-12 h-12',
      large: 'w-16 h-16'
    }.freeze

    def initialize(name: nil, colour_string: nil, url: nil, size: SIZE_DEFAULT, **system_arguments)
      @name = name
      @initials = name.chr
      @colours = generate_hsla_colour(colour_string || name)
      @size = size
      @url = url
      @font_styles = if %i[xs small].include?(size)
                       'text-sm'
                     else
                       size == :medium ? 'text-2xl font-semibold' : 'text-4xl font-bold'
                     end
      @system_arguments = system_arguments
    end

    def generate_hsla_colour(name)
      h = name.hash.abs % 360
      { border: "hsla(#{h}, 100%, var(--tw-avatar-border-lightness), var(--tw-avatar-bg-alpha))",
        background: "hsla(#{h}, 100%, var(--tw-avatar-bg-lightness), var(--tw-avatar-bg-alpha))" }
    end

    def system_arguments
      @system_arguments.tap do |opts|
        opts[:tag] = @url ? :a : :div
        (opts[:role] = :img) unless @url
        (opts[:href] = @url) if @url
        opts[:style] = "background-color: #{@colours[:background]}; border: 1px solid #{@colours[:border]};"
        opts[:aria] = { label: @name }
        opts[:classes] = class_names(
          'avatar',
          SIZE_MAPPINGS[@size],
          opts[:classes]
        )
      end
    end
  end
end
