# frozen_string_literal: true

module GlobalSearch
  # Orchestrates mixed, permission-safe search across multiple resources.
  class Query < BaseService
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

      provider_results = search_providers(search_params)
      results = sort_and_limit(provider_results, search_params)

      GlobalSearch::Response.new(query: search_params.query, meta: build_meta(search_params), results:)
    end

    private

    def search_providers(search_params)
      search_params.types.flat_map do |type|
        provider_for(type).search(
          query: search_params.query,
          match_sources: search_params.match_sources,
          filters: search_params.filters,
          limit: search_params.per_type_limit
        )
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
        meta: build_meta(search_params),
        results: []
      )
    end

    def build_meta(search_params)
      filters = search_params.filters

      {
        types: search_params.types,
        match_sources: search_params.match_sources,
        sort: search_params.sort,
        workflow_state: filters[:workflow_state],
        created_from: filters[:created_from]&.iso8601,
        created_to: filters[:created_to]&.iso8601,
        per_type_limit: search_params.per_type_limit,
        limit: search_params.limit
      }
    end
  end
end
