# frozen_string_literal: true

# Shared plumbing for query-form objects that support:
# - `advanced_query` toggle based on groups
# - optional pagination via Pagy
# - Ransack filtering
# - sorting (including JSONB metadata sorting)
#
# Including classes must provide:
# - `model_class` (e.g., Sample)
# - `filter_column` (e.g., :project_id)
# - `filter_ids` (e.g., project_ids)
# - `ransack_params`
# - `add_condition(scope, condition)`
#
# Optionally override:
# - `search_scope` (defaults to `model_class`)
module AdvancedSearch
  # Handles query execution with pagination, filtering, and sorting.
  module Querying
    extend ActiveSupport::Concern

    def results(**results_arguments)
      if results_arguments[:limit] || results_arguments[:page]
        pagy_results(results_arguments[:limit], results_arguments[:page])
      else
        non_pagy_results
      end
    end

    private

    def pagy_results(limit, page)
      pagy(ransack_results, limit:, page:)
    end

    def non_pagy_results
      ransack_results
    end

    def ransack_results
      return model_class.none unless valid?

      scope = advanced_query ? advanced_query_scope : filtered_scope
      apply_sort(scope).ransack(ransack_params).result
    end

    def advanced_query_scope
      filtered_scope.and(advanced_query_groups)
    end

    def advanced_query_groups
      adv_query_scope = nil

      groups.each do |group|
        group_scope = model_class

        group.conditions.each do |condition|
          group_scope = add_condition(group_scope, condition)
        end

        adv_query_scope = if adv_query_scope.nil?
                            group_scope
                          else
                            adv_query_scope.or(group_scope)
                          end
      end

      adv_query_scope
    end

    def filtered_scope
      search_scope.where(filter_column => filter_ids)
    end

    def apply_sort(scope)
      return scope unless column.present? && direction.present?

      if column.starts_with?('metadata.')
        field = column.delete_prefix('metadata.')
        scope.order(model_class.metadata_sort(field, direction))
      else
        scope.order(column => direction)
      end
    end

    def search_scope
      model_class
    end
  end
end
