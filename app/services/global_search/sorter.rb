# frozen_string_literal: true

module GlobalSearch
  # Sorts and applies diversity to global search results.
  class Sorter
    def initialize(results, sort:, selected_types:)
      @results = results
      @sort = sort
      @selected_types = selected_types
    end

    def call
      case @sort
      when 'most_recent'
        sort_by_most_recent
      else
        sort_by_best_match
      end
    end

    private

    def sort_by_best_match
      @results.sort_by do |result|
        [result.score_bucket.to_i, -time_sort_value(result.updated_at), result.type, result.record_id.to_s]
      end
    end

    def sort_by_most_recent
      ordered = @results.sort_by do |result|
        [-time_sort_value(result.updated_at), result.type, result.record_id.to_s]
      end
      return ordered if @selected_types.one?

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
