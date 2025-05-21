# frozen_string_literal: true

module Pathogen
  class Form::RadioButtonComponentPreview < ViewComponent::Preview
    # @label Default
    # @param label text
    # @param checked toggle
    # @param disabled toggle
    # @param required toggle
    # @param invalid toggle
    def default(label: "Option", checked: false, disabled: false, required: false, invalid: false)
      user = User.new
      form = ActionView::Helpers::FormBuilder.new(:user, user, ActionView::Base.new, {})
      
      render_with_template(
        template: 'radio_button_component_preview/default',
        locals: {
          form: form,
          label: label,
          checked: checked,
          disabled: disabled,
          required: required,
          invalid: invalid
        }
      )
    end
  end
end
