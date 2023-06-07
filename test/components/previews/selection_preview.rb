# frozen_string_literal: true

class SelectionPreview < Lookbook::Preview
  # The selection controller stores the values of checkboxes in local storage. The local storage key is the url.
  # When a user toggles a checkbox, the value is updated in local storage.
  def default; end

  # The selection controller stores the values of checkboxes in local storage. The local storage key is the url.
  # This example uses the selection controller within a table to select/deselect rows.
  # When a user toggles a checkbox, the value is updated in local storage.
  def within_a_table; end
end
