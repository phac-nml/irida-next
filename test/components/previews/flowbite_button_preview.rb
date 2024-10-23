# frozen_string_literal: true

class FlowbiteButtonPreview < ViewComponent::Preview
  # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
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

  # @param disabled toggle "The Boolean disabled attribute, when present, makes the element not mutable, focusable, or even submitted with the form. The user can neither edit nor focus on the control, nor its form control descendants."
  # @param block toggle "If true, the button will take up the full width of its container."
  def primary(disabled: false, block: false)
    render Flowbite::Button.new(scheme: :primary, disabled:, block:) do
      'Button'
    end
  end

  # @param disabled toggle "The Boolean disabled attribute, when present, makes the element not mutable, focusable, or even submitted with the form. The user can neither edit nor focus on the control, nor its form control descendants."
  # @param block toggle "If true, the button will take up the full width of its container."
  def danger(disabled: false, block: false)
    render Flowbite::Button.new(scheme: :danger, disabled:, block:) do
      'Button'
    end
  end

  def all_schemes; end

  def full_width
    render Flowbite::Button.new(block: true) do
      'Button'
    end
  end
end
