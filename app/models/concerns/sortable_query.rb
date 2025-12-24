# frozen_string_literal: true

# Concern for query form objects that accept a `sort` string and translate it into
# separate `column` and `direction` attributes.
module SortableQuery
  extend ActiveSupport::Concern

  DEFAULT_SORT = 'updated_at desc'

  def sort=(value)
    super

    # Use rpartition to split on the first space encountered from the right side.
    # This allows us to sort by metadata fields which contain spaces.
    sort_value = sort.presence || default_sort
    sort_column, _space, sort_direction = sort_value.rpartition(' ')

    # Fallback to default if column is empty (e.g., if sort was just "desc")
    if sort_column.blank?
      sort_column = 'updated_at'
      sort_direction = sort_direction.presence || 'desc'
    end

    sort_column = sort_column.gsub('metadata_', 'metadata.') if sort_column.match?(/metadata_/)

    assign_attributes(column: sort_column, direction: sort_direction)
  end

  private

  def default_sort
    DEFAULT_SORT
  end
end
