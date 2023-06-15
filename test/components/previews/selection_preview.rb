# frozen_string_literal: true

class SelectionPreview < ViewComponent::Preview
  # The selection controller stores the values of checkboxes in session storage. The default storage key is the
  # url. When a user toggles a checkbox, the value is updated in session storage.
  def default; end

  # The selection controller stores the values of checkboxes in session storage. The default storage key is the
  # url. This example uses a set storage key.
  def with_a_storage_key; end

  # The selection controller stores the values of checkboxes in session storage. The default storage key is the
  # url. This example uses the selection controller within a table to select/deselect rows.
  # When a user toggles a checkbox, the value is updated in session storage.
  def within_a_table; end
end
