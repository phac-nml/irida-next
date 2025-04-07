# frozen_string_literal: true

# 🎯 TableHelper provides accessibility-focused table sorting utilities
#
# 📚 This module enhances table functionality by providing helper methods
# for managing table sorting states and ARIA attributes, ensuring both
# visual and screen-reader accessibility.
module TableHelper
  # 🔍 Generates ARIA sort attributes for table column headers
  #
  # @param column [String, Symbol] 📊 The column identifier
  # @param sort_key [String] 🔑 The current sort column
  # @param sort_direction [String] ⬆️ The current sort direction ('asc' or 'desc')
  #
  # @return [Hash] 🏷️ A hash of ARIA attributes for the column header
  #   - Returns empty hash if column is not currently sorted
  #   - Returns { 'aria-sort': 'ascending' } or { 'aria-sort': 'descending' } if sorted
  #
  # @example Setting ARIA attributes on a column header
  #   <%= content_tag :th, **aria_sort('name', params[:sort], params[:direction]) %>
  def aria_sort(column, sort_key, sort_direction)
    return {} unless sort_key.present? && sort_key == column.to_s

    { 'aria-sort': sort_direction == 'desc' ? 'descending' : 'ascending' }
  end
end
