# frozen_string_literal: true

module GlobalSearch
  # Normalizes and validates query parameters for global search.
  class Params
    DEFAULT_TYPES = %w[projects groups workflow_executions samples data_exports].freeze
    DEFAULT_MATCH_SOURCES = %w[identifier name].freeze
    ALLOWED_MATCH_SOURCES = %w[identifier name metadata].freeze
    ALLOWED_SORTS = %w[best_match most_recent].freeze

    DEFAULT_PER_TYPE_LIMIT = 20
    DEFAULT_LIMIT = 100

    MAX_PER_TYPE_LIMIT = 50
    MAX_LIMIT = 200

    def initialize(params)
      @params = params
    end

    def query
      @params[:q].to_s.strip
    end

    def types
      requested = Array(@params[:types]).map(&:to_s)
      valid = requested & DEFAULT_TYPES
      valid.presence || DEFAULT_TYPES
    end

    def match_sources
      requested = Array(@params[:match_sources]).map(&:to_s)
      valid = requested & ALLOWED_MATCH_SOURCES
      valid.presence || DEFAULT_MATCH_SOURCES
    end

    def sort
      value = @params[:sort].to_s
      ALLOWED_SORTS.include?(value) ? value : 'best_match'
    end

    def workflow_state
      state = @params[:workflow_state].to_s
      return nil if state.blank?

      state if WorkflowExecution.states.key?(state)
    end

    def per_type_limit
      value = @params[:per_type_limit].presence || DEFAULT_PER_TYPE_LIMIT
      value.to_i.clamp(1, MAX_PER_TYPE_LIMIT)
    end

    def limit
      value = @params[:limit].presence || DEFAULT_LIMIT
      value.to_i.clamp(1, MAX_LIMIT)
    end

    def filters
      {
        workflow_state:,
        created_from: parse_date(@params[:created_from], boundary: :start),
        created_to: parse_date(@params[:created_to], boundary: :end)
      }
    end

    private

    def parse_date(date_string, boundary:)
      return nil if date_string.blank?

      date = Date.iso8601(date_string.to_s)
      boundary == :start ? date.beginning_of_day : date.end_of_day
    rescue ArgumentError
      nil
    end
  end
end
