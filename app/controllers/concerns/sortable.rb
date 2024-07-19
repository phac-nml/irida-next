# frozen_string_literal: true

# Module Sortable provides a default sorting mechanism for ActiveRecord models.
# It is designed to be included in controllers to standardize the sorting of database records.
# This module extends ActiveSupport::Concern to allow its methods to be easily integrated
# into any controller that includes it.
module Sortable
  extend ActiveSupport::Concern

  # Sets a before_action hook to apply sorting before the index action is called.
  included do
    before_action :set_sorting, only: %i[index] # rubocop:disable Rails/LexicallyScopedActionFilter
  end

  private

  # Returns the default sorting string for database queries.
  # This method can be overridden in the controller to provide a custom sort order.
  # @return [String] the default sort order in the format 'column_name direction'.
  # It defaults to sorting records by 'updated_at' in descending order.
  def default_sort
    'updated_at desc'
  end

  # Sets the sorting parameter for the query object `@q`.
  # This method is intended to be called before the index action to ensure that
  # records are sorted according to the default sort order if no other sort order is specified.
  # It checks if the `@q` object's sorts array is empty and sets it to the default sort order if true.
  def set_sorting
    @q.sorts = default_sort if @q.sorts.empty?
  end
end
