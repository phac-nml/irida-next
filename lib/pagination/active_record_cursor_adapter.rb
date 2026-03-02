# frozen_string_literal: true

module Pagination
  # Wraps active_record_cursor_paginate and returns a stable page contract object.
  class ActiveRecordCursorAdapter
    DEFAULT_LIMIT = 20
    MAX_LIMIT = 100

    def initialize(relation)
      @relation = relation
    end

    def fetch(limit: DEFAULT_LIMIT, after: nil)
      paginator = build_paginator(limit:, after:)
      result = paginator.fetch

      ActiveRecordCursorPage.new(
        records: result.records,
        next_cursor: next_cursor_for(result),
        has_next_page: result.has_next?,
        total_count: paginator.total_count
      )
    end

    private

    attr_reader :relation

    def build_paginator(limit:, after:)
      paginator = relation.cursor_paginate
      paginator.order = ActiveRecordCursorOrdering.order(relation) { |direction| direction }
      paginator.nullable_columns = ActiveRecordCursorOrdering.nullable_columns(relation)
      paginator.limit = clamp_limit(limit)

      normalized_after = normalize_cursor(after)
      paginator.after = normalized_after if normalized_after.present?

      paginator
    end

    def normalize_cursor(cursor)
      return nil if cursor.nil?

      normalized_cursor = cursor.is_a?(String) ? cursor.strip : cursor
      return nil if ['', 'null'].include?(normalized_cursor)

      normalized_cursor
    end

    def clamp_limit(limit)
      normalized_limit = limit.to_i
      normalized_limit = DEFAULT_LIMIT if normalized_limit <= 0

      [normalized_limit, MAX_LIMIT].min
    end

    def next_cursor_for(result)
      return nil unless result.has_next?

      last_record = result.records.last
      return nil if last_record.nil?

      result.cursor_for(last_record)
    end
  end
end
