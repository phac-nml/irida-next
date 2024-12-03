# frozen_string_literal: true

module Pathogen
  # Preview class for the Button component
  class ButtonPreview < ViewComponent::Preview
    # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
    # @param size select { choices: [small, medium] } "The size of the button."
    # @param disabled toggle
    #   "The Boolean disabled attribute, when present, makes the element not mutable,
    #   focusable, or even submitted with the form. The user can neither edit nor focus
    #   on the control, nor its form control descendants."
    # @param block toggle "If true, the button will take up the full width of its container."
    def playground(scheme: :default, size: :medium, disabled: false, block: false)
      render Pathogen::Button.new(scheme:, size:, disabled:, block:, test_selector: 'playground') do
        'Button'
      end
    end

    # @param disabled toggle
    #   "The Boolean disabled attribute, when present, makes the element not mutable,
    #   focusable, or even submitted with the form. The user can neither edit nor focus
    #   on the control, nor its form control descendants."
    def default(disabled: false)
      render Pathogen::Button.new(disabled:, test_selector: 'default') do
        'Button'
      end
    end

    # @param disabled toggle
    #   "The Boolean disabled attribute, when present, makes the element not mutable,
    #   focusable, or even submitted with the form. The user can neither edit nor focus
    #   on the control, nor its form control descendants."
    # @param block toggle "If true, the button will take up the full width of its container."
    def primary(disabled: false, block: false)
      render Pathogen::Button.new(scheme: :primary, disabled:, block:, test_selector: 'primary') do
        'Button'
      end
    end

    # @param disabled toggle
    #   "The Boolean disabled attribute, when present, makes the element not mutable,
    #   focusable, or even submitted with the form. The user can neither edit nor focus
    #   on the control, nor its form control descendants."
    # @param block toggle "If true, the button will take up the full width of its container."
    def danger(disabled: false, block: false)
      render Pathogen::Button.new(scheme: :danger, disabled:, block:, test_selector: 'danger') do
        'Button'
      end
    end

    def all_schemes; end

    def full_width
      render Pathogen::Button.new(block: true, test_selector: 'full-width') do
        'Button'
      end
    end

    # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
    # @param href text "The URL to link to."
    # @param disabled toggle
    #   "The Boolean disabled attribute, when present, makes the element not mutable,
    #   focusable, or even submitted with the form. The user can neither edit nor focus
    #   on the control, nor its form control descendants."
    def link_as_a_button(scheme: :default, href: '#', disabled: false)
      render Pathogen::Button.new(scheme:, href:, tag: :a, disabled:, test_selector: 'link-as-a-button') do
        'Button'
      end
    end

    # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
    # @param size select { choices: [small, medium] } "The size of the button."
    def leading_visual(scheme: :primary, size: :medium)
      render_with_template(locals: {
                             scheme:,
                             size:
                           })
    end

    # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
    # @param size select { choices: [small, medium] } "The size of the button."
    def leading_visual_svg(scheme: :primary, size: :medium)
      render_with_template(locals: {
                             scheme:,
                             size:
                           })
    end

    # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
    # @param size select { choices: [small, medium] } "The size of the button."
    def trailing_visual(scheme: :primary, size: :medium)
      render_with_template(locals: {
                             scheme:,
                             size:
                           })
    end

    # @param scheme select { choices: [default,primary, danger] } "The color scheme of the button."
    # @param size select { choices: [small, medium] } "The size of the button."
    def trailing_visual_svg(scheme: :primary, size: :medium)
      render_with_template(locals: {
                             scheme:,
                             size:
                           })
    end
  end
end
