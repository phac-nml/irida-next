# frozen_string_literal: true

class ConfirmationComponentPreview < ViewComponent::Preview
  # Default Confirmation Dialog
  # ---------------------------
  # Text provided through the `data-turbo-confirm` attribute will be used as the confirmation message
  def default; end

  # Custom Confirmation Dialog Content
  # ----------------------------------
  # Added the `data-turbo-content` attribute to the dom **id** for custom content
  # This can include HTML
  def custom_content; end

  # Custom Confirmation Dialog Form
  # -------------------------------
  # The entire contents of the modal can be overridden with the `data-turbo-form` attribute
  # This accepts the **id** for the form to be rendered
  # Buttons must be provided in the form
  #   <button value='cancel'>Cancel</button>
  #   <button value='confirm'>Confirm</button>
  def with_confirm_value; end
end
