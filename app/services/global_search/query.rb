# frozen_string_literal: true

module GlobalSearch
  # Orchestrates mixed, permission-safe search across multiple resources.
  class Query < BaseService # rubocop:disable Metrics/ClassLength
    DEFAULT_TYPES = %w[projects groups workflow_executions samples data_exports].freeze
    DEFAULT_MATCH_SOURCES = %w[identifier name].freeze
    ALLOWED_MATCH_SOURCES = %w[identifier name metadata].freeze
    ALLOWED_SORTS = %w[best_match most_recent].freeze

    DEFAULT_SUGGEST_PER_TYPE_LIMIT = 5
    DEFAULT_SUGGEST_LIMIT = 20
    DEFAULT_INDEX_PER_TYPE_LIMIT = 20
    DEFAULT_INDEX_LIMIT = 100

    MAX_PER_TYPE_LIMIT = 50
    MAX_LIMIT = 200

    PROVIDERS = {
      'projects' => GlobalSearch::Providers::Projects,
      'groups' => GlobalSearch::Providers::Groups,
      'workflow_executions' => GlobalSearch::Providers::WorkflowExecutions,
      'samples' => GlobalSearch::Providers::Samples,
      'data_exports' => GlobalSearch::Providers::DataExports
    }.freeze

    def execute # rubocop:disable Metrics/MethodLength
      query = normalized_query
      return empty_response(query:) if query.blank?

      types = selected_types
      match_sources = selected_match_sources
      sort = selected_sort
      filters = search_filters
      per_type_limit = selected_per_type_limit
      limit = selected_limit

      provider_results = types.flat_map do |type|
        provider_for(type).search(
          query:,
          match_sources:,
          filters:,
          limit: per_type_limit
        )
      end

      results = sort_results(provider_results, sort:, selected_types: types).first(limit)

      GlobalSearch::Response.new(
        query:,
        meta: build_meta(
          types:,
          match_sources:,
          sort:,
          filters:,
          limits: {
            per_type_limit:,
            limit:
          }
        ),
        results:
      )
    end

    private

    def provider_for(type)
      PROVIDERS.fetch(type).new(current_user)
    end

    def empty_response(query:)
      filters = search_filters

      GlobalSearch::Response.new(
        query:,
        meta: build_meta(
          types: selected_types,
          match_sources: selected_match_sources,
          sort: selected_sort,
          filters:,
          limits: {
            per_type_limit: selected_per_type_limit,
            limit: selected_limit
          }
        ),
        results: []
      )
    end

    def normalized_query
      params[:q].to_s.strip
    end

    def selected_types
      requested_types = Array(params[:types]).map(&:to_s)
      valid = requested_types & DEFAULT_TYPES
      valid.presence || DEFAULT_TYPES
    end

    def selected_match_sources
      requested_sources = Array(params[:match_sources]).map(&:to_s)
      valid = requested_sources & ALLOWED_MATCH_SOURCES
      valid.presence || DEFAULT_MATCH_SOURCES
    end

    def selected_sort
      sort = params[:sort].to_s
      ALLOWED_SORTS.include?(sort) ? sort : 'best_match'
    end

    def selected_workflow_state
      state = params[:workflow_state].to_s
      return nil if state.blank?

      return state if WorkflowExecution.states.key?(state)

      nil
    end

    def selected_per_type_limit
      default = suggest? ? DEFAULT_SUGGEST_PER_TYPE_LIMIT : DEFAULT_INDEX_PER_TYPE_LIMIT
      value = params[:per_type_limit].presence || default
      value.to_i.clamp(1, MAX_PER_TYPE_LIMIT)
    end

    def selected_limit
      default = suggest? ? DEFAULT_SUGGEST_LIMIT : DEFAULT_INDEX_LIMIT
      value = params[:limit].presence || default
      value.to_i.clamp(1, MAX_LIMIT)
    end

    def suggest?
      ActiveModel::Type::Boolean.new.cast(params[:suggest])
    end

    def parse_date(date_string, boundary:)
      return nil if date_string.blank?

      date = Date.iso8601(date_string.to_s)
      boundary == :start ? date.beginning_of_day : date.end_of_day
    rescue ArgumentError
      nil
    end

    def search_filters
      {
        workflow_state: selected_workflow_state,
        created_from: parse_date(params[:created_from], boundary: :start),
        created_to: parse_date(params[:created_to], boundary: :end)
      }
    end

    def build_meta(types:, match_sources:, sort:, filters:, limits:)
      {
        types:,
        match_sources:,
        sort:,
        workflow_state: filters[:workflow_state],
        created_from: filters[:created_from]&.iso8601,
        created_to: filters[:created_to]&.iso8601,
        per_type_limit: limits[:per_type_limit],
        limit: limits[:limit],
        suggest: suggest?
      }
    end

    def sort_results(results, sort:, selected_types:)
      case sort
      when 'most_recent'
        sort_by_most_recent(results, selected_types:)
      else
        sort_by_best_match(results)
      end
    end

    def sort_by_best_match(results)
      results.sort_by do |result|
        [result.score_bucket.to_i, -time_sort_value(result.updated_at), result.type, result.record_id.to_s]
      end
    end

    def sort_by_most_recent(results, selected_types:)
      ordered = results.sort_by do |result|
        [-time_sort_value(result.updated_at), result.type, result.record_id.to_s]
      end
      return ordered if selected_types.one?

      apply_soft_diversity(ordered)
    end

    def apply_soft_diversity(results) # rubocop:disable Metrics/MethodLength
      head_target = [10, results.size].min
      remaining = results.dup
      head = []
      last_type = nil
      current_streak = 0

      while head.size < head_target && remaining.any?
        index = remaining.index do |result|
          current_streak < 4 || result.type != last_type
        end
        index ||= 0

        selected = remaining.delete_at(index)

        if selected.type == last_type
          current_streak += 1
        else
          last_type = selected.type
          current_streak = 1
        end

        head << selected
      end

      head + remaining
    end

    def time_sort_value(timestamp)
      timestamp.to_i
    end
  end
end
