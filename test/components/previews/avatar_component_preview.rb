# frozen_string_literal: true

class AvatarComponentPreview < ViewComponent::Preview
  include Pathogen::ViewHelper

  # @label Overview
  def default
    render_with_template(locals: preview_locals)
  end

  # @label Sizes
  def sizes
    render_with_template(locals: preview_locals)
  end

  # @label In context
  def in_context
    render_with_template(locals: preview_locals)
  end

  # @label Accessibility
  def accessibility
    render_with_template(locals: preview_locals)
  end

  private

  def preview_locals
    user = User.new(first_name: 'Alex', last_name: 'Chen', email: 'alex.chen@phac-aspc.gc.ca')

    {
      user:,
      user_label: user.full_name.presence || user.email,
      user_initials: user.avatar_initials,
      user_colour_seed: "#{user.id}-#{user.email}",
      namespace_label: 'Streptococcus Outbreak 2021',
      namespace_colour_seed: 'Streptococcus Outbreak 2021-42'
    }
  end
end
