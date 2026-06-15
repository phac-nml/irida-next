# frozen_string_literal: true

# Displays a user's initials on a deterministic coloured background.
class UserAvatarComponent < Component
  attr_reader :user, :initials, :size, :font_styles

  SIZE_DEFAULT = :medium
  SIZE_MAPPINGS = {
    xs: 'w-6 h-6 rounded-sm',
    small: 'w-8 h-8',
    medium: 'w-12 h-12',
    large: 'w-16 h-16'
  }.freeze

  def initialize(user:, size: SIZE_DEFAULT, **system_arguments)
    @user = user
    @initials = user.avatar_initials
    @colours = generate_hsla_colour("#{user.id}-#{user.email}")
    @size = size
    @font_styles = font_styles_for(size)
    @system_arguments = system_arguments
  end

  def system_arguments
    @system_arguments.tap do |opts|
      opts[:role] = :img
      opts[:style] = "background-color: #{@colours[:background]}; border: 1px solid #{@colours[:border]};"
      opts[:aria] = { label: user.full_name }
      opts[:class] = class_names(
        'avatar',
        SIZE_MAPPINGS[@size],
        opts[:class]
      )
    end
  end

  private

  def font_styles_for(size)
    if %i[xs small].include?(size)
      'text-sm'
    else
      size == :medium ? 'text-2xl font-semibold' : 'text-4xl font-bold'
    end
  end

  def generate_hsla_colour(seed)
    h = Digest::MD5.hexdigest(seed).to_i(16) % 360
    {
      border: "hsla(#{h}, 100%, var(--tw-avatar-border-lightness), var(--tw-avatar-bg-alpha))",
      background: "hsla(#{h}, 100%, var(--tw-avatar-bg-lightness), var(--tw-avatar-bg-alpha))"
    }
  end
end
