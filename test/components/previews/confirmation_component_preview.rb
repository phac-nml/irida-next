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
  # This is used when you want to force the user to confirm that they want to continue
  # by making them enter a specific value into the input.
  # Example: If they want to delete the project, they will need to enter the project name
  def with_confirm_value; end
end
