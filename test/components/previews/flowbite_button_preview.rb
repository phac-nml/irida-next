# frozen_string_literal: true

class FlowbiteButtonPreview < ViewComponent::Preview
  # @param scheme select { choices: [default,primary, blue, alternative, dark, light, green, red, purple, yellow] } "The color scheme of the button."
  # @param size select { choices: [small, medium] } "The size of the button."
  # @param disabled toggle "The Boolean disabled attribute, when present, makes the element not mutable, focusable, or even submitted with the form. The user can neither edit nor focus on the control, nor its form control descendants."
  # @param block toggle "If true, the button will take up the full width of its container."
  def playground(scheme: :default, size: :medium, disabled: false, block: false)
    render Flowbite::Button.new(scheme:, size:, disabled:, block:) do
      'Button'
    end
  end

  # @param disabled toggle "The Boolean disabled attribute, when present, makes the element not mutable, focusable, or even submitted with the form. The user can neither edit nor focus on the control, nor its form control descendants."
  def default(disabled: false)
    render Flowbite::Button.new(disabled:) do
      'Button'
    end
  end

  def button_sizes; end
  def button_sizes_with_icon; end
  def buttons_with_icons; end
end
