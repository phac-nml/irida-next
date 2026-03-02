# frozen_string_literal: true

module GlobalSearch
  # Orchestrates mixed, permission-safe search across multiple resources.
  class Query < BaseService
    GROUP_ORDER = GlobalSearch::Params::DEFAULT_TYPES

    PROVIDERS = {
      'projects' => GlobalSearch::Providers::Projects,
      'groups' => GlobalSearch::Providers::Groups,
      'workflow_executions' => GlobalSearch::Providers::WorkflowExecutions,
      'samples' => GlobalSearch::Providers::Samples,
      'data_exports' => GlobalSearch::Providers::DataExports
    }.freeze

    def execute
      search_params = GlobalSearch::Params.new(params)
      return empty_response(search_params) if search_params.query.blank?

      count_results, display_results = results_for(search_params)
      results = sort_and_limit(display_results, search_params)

      GlobalSearch::Response.new(
        query: search_params.query,
        meta: build_meta(search_params, count_results),
        results:
      )
    end

    private

    def search_providers(search_params, types:)
      types.flat_map do |type|
        provider_for(type).search(
          query: search_params.query,
          match_sources: search_params.match_sources,
          filters: search_params.filters,
          limit: search_params.per_type_limit
        )
      end
    end

    # Returns [count_results, display_results].
    # When active_type is set, all providers run once and results are filtered
    # in Ruby, eliminating the previous double-query pattern.
    # When active_type is absent, only the selected type providers run.
    def results_for(search_params)
      if search_params.active_type.present?
        all = search_providers(search_params, types: GROUP_ORDER)
        display = all.select { |r| r.type == search_params.active_type }
        [all, display]
      else
        results = search_providers(search_params, types: search_params.types)
        [results, results]
      end
    end

    def sort_and_limit(results, search_params)
      GlobalSearch::Sorter.new(results, sort: search_params.sort, selected_types: search_params.types)
                          .call
                          .first(search_params.limit)
    end

    def provider_for(type)
      PROVIDERS.fetch(type).new(current_user)
    end

    def empty_response(search_params)
      GlobalSearch::Response.new(
        query: search_params.query,
        meta: build_meta(search_params, []),
        results: []
      )
    end

    def build_meta(search_params, count_results)
      filters = search_params.filters

      {
        types: search_params.types,
        active_type: search_params.active_type,
        match_sources: search_params.match_sources,
        sort: search_params.sort,
        workflow_state: filters[:workflow_state],
        created_from: filters[:created_from]&.iso8601,
        created_to: filters[:created_to]&.iso8601,
        per_type_limit: search_params.per_type_limit,
        limit: search_params.limit,
        counts_by_type: counts_by_type(count_results),
        group_order: GROUP_ORDER
      }
    end

    def counts_by_type(results)
      tally = results.group_by(&:type).to_h { |type, grouped| [type, grouped.size] }

      GROUP_ORDER.index_with { |type| tally.fetch(type, 0) }
    end
  end
end
