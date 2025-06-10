# frozen_string_literal: true

class Pathogen::IconHelperPreview < ViewComponent::Preview
  # @!group Basic Usage
  def default
    render_with_template(locals: { icon: Pathogen::ICON::CLIPBOARD })
  end

  def with_custom_class
    render_with_template(locals: { icon: Pathogen::ICON::CLIPBOARD, class: 'h-8 w-8 text-primary-600' })
  end

  def with_data_attributes
    render_with_template(locals: { icon: Pathogen::ICON::CLIPBOARD, data: { 'test-selector': 'custom-icon' } })
  end
  # @!endgroup

  # @!group Icon Types
  def phosphor_icon
    render_with_template(locals: { icon: Pathogen::ICON::CLIPBOARD })
  end

  def heroicon
    render_with_template(locals: { icon: Pathogen::ICON::BEAKER })
  end

  def named_icon
    render_with_template(locals: { icon: Pathogen::ICON::IRIDA_LOGO })
  end
  # @!endgroup

  # @!group Common Icons
  def clipboard
    render_with_template(locals: { icon: Pathogen::ICON::CLIPBOARD })
  end

  def user_circle
    render_with_template(locals: { icon: Pathogen::ICON::USER_CIRCLE })
  end

  def gear_six
    render_with_template(locals: { icon: Pathogen::ICON::GEAR_SIX })
  end
  # @!endgroup
end
