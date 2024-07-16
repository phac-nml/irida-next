# frozen_string_literal: true

# Module FilteredSort provides a default sorting mechanism for ActiveRecord models.
# It is designed to be included in controllers to standardize the sorting of database records.
# This module extends ActiveSupport::Concern to allow its methods to be easily integrated
# into any controller that includes it.
module FilteredSort
  extend ActiveSupport::Concern

  included do
    before_action :set_sorting, only: %i[index]
  end

  private

  # Returns the default sorting string for database queries.
  # This method can be overridden in the controller to provide a custom sort order.
  # @return [String] the default sort order in the format 'column_name direction'.
  def default_sort
    'created_at desc'
  end

  # Sets the sorting order for the query object `@q`.
  # If `@q` does not have any sorts applied, it defaults to the order specified by `default_sort`.
  # This method is intended to be called within a controller action to apply sorting.
  def set_sorting
    # remove metadata sort if metadata not visible
    if !@q.sorts.empty? && @q.sorts.first.name.start_with?('metadata_') && search_params[:metadata].to_i != 1
      @q.sorts.slice!(0)
    end

    @q.sorts = default_sort if @q.sorts.empty?
  end
end
