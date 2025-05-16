# frozen_string_literal: true

class PathogenButtonPreview < ViewComponent::Preview
  # @param scheme select { choices: [default, primary, danger, ghost] } "The color scheme of the button."
  # @param size select { choices: [small, medium] } "The size of the button."
  # @param disabled toggle "The Boolean disabled attribute, when present, makes the element not mutable, focusable, or even submitted with the form."
  # @param block toggle "If true, the button will take up the full width of its container."
  def playground(scheme: :default, size: :medium, disabled: false, block: false)
    render Pathogen::Button.new(scheme:, size:, disabled:, block:, test_selector: 'playground') do
      'Button'
    end
  end

  # Shows all available button states and variants in a single view
  # @param size select { choices: [small, medium] } "The size of the button."
  def all_states_and_variants(size: :medium)
    render_with_template(locals: { size: })
  end

  # Shows all visual elements (icons, SVGs) in different configurations
  # @param size select { choices: [small, medium] } "The size of the button."
  def visual_elements(size: :medium)
    render_with_template(locals: { size: })
  end
end
