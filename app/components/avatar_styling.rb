# frozen_string_literal: true

# Shared avatar size mappings, typography, and deterministic colour generation.
module AvatarStyling
  SIZE_DEFAULT = :medium
  SIZE_MAPPINGS = {
    xs: 'w-6 h-6 rounded-sm',
    small: 'w-8 h-8',
    medium: 'w-12 h-12',
    large: 'w-16 h-16'
  }.freeze

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
