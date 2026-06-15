# frozen_string_literal: true

# Displays a user's initials on a deterministic coloured background.
class UserAvatarComponent < Component
  include AvatarStyling

  attr_reader :user, :initials, :size, :font_styles

  def initialize(user:, size: SIZE_DEFAULT, decorative: false, **system_arguments)
    @user = user
    @decorative = decorative
    @initials = user.avatar_initials
    @colours = generate_hsla_colour("#{user.id}-#{user.email}")
    @size = size
    @font_styles = font_styles_for(size)
    @system_arguments = system_arguments
  end

  def system_arguments
    @system_arguments.tap do |opts|
      if @decorative
        opts[:aria] = { hidden: true }
      else
        opts[:role] = :img
        opts[:aria] = { label: user.full_name }
      end
      opts[:style] = "background-color: #{@colours[:background]}; border: 1px solid #{@colours[:border]};"
      opts[:class] = class_names(
        'avatar',
        SIZE_MAPPINGS[@size],
        opts[:class]
      )
    end
  end
end
