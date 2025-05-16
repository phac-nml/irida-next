# frozen_string_literal: true

class PathogenButtonPreview < ViewComponent::Preview
  # @param scheme select { choices: [default, primary, danger, ghost, unstyled] } "The color scheme of the button."
  def playground(scheme: :default)
    render Pathogen::Button.new(scheme:, test_selector: 'playground') do
      'Button'
    end
  end

  # Shows all available button states and variants in a single view
  def all_states_and_variants
    render_with_template
  end

  # Shows all visual elements (icons, SVGs) in different configurations
  def visual_elements
    render_with_template
  end

  # Shows all available button schemes
  def all_schemes
    render_with_template
  end
end
