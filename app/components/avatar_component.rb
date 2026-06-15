# frozen_string_literal: true

# Displays initials on a deterministic coloured background.
class AvatarComponent < Component
  include AvatarStyling

  attr_reader :initials, :size, :font_styles, :tag_name

  # rubocop:disable Metrics/ParameterLists
  def initialize(label:, initials: nil, colour_seed: nil, url: nil, size: SIZE_DEFAULT, decorative: false,
                 **system_arguments)
    raise ArgumentError, 'label is required' if label.blank?

    @label = label
    @decorative = decorative
    @initials = initials.presence || label.to_s.strip.first
    @colours = generate_hsla_colour(colour_seed.presence || label)
    @size = size
    @font_styles = font_styles_for(size)
    @tag_name = url.present? ? :a : :span
    @system_arguments = system_arguments
    @system_arguments[:href] = url if url.present?
  end
  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/MethodLength
  def system_arguments
    @system_arguments.tap do |opts|
      if @decorative
        opts[:aria] = { hidden: true }
      else
        opts[:role] = :img unless tag_name == :a
        opts[:aria] = { label: @label }
      end
      opts[:style] = "background-color: #{@colours[:background]}; border: 1px solid #{@colours[:border]};"
      class_name = opts[:class] || opts[:classes]
      classes = class_names(
        'avatar',
        SIZE_MAPPINGS[@size],
        class_name
      )
      opts[:class] = classes
      opts.delete(:classes)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
