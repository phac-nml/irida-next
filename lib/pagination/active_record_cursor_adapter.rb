# frozen_string_literal: true

module Pagination
  # Wraps active_record_cursor_paginate and returns a stable page contract object.
  class ActiveRecordCursorAdapter
    DEFAULT_LIMIT = 50

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
        total_count: relation.reorder(nil).count
      )
    end

    private

    attr_reader :relation

    def build_paginator(limit:, after:)
      paginator = relation.cursor_paginate
      paginator.order = ActiveRecordCursorOrdering.order(relation) { |direction| direction }
      paginator.nullable_columns = ActiveRecordCursorOrdering.nullable_columns(relation)
      paginator.limit = limit || DEFAULT_LIMIT

      normalized_after = normalize_cursor(after)
      paginator.after = normalized_after if normalized_after.present?

      paginator
    end

    def normalize_cursor(cursor)
      return nil if ['', 'null'].include?(cursor)

      cursor
    end

    def next_cursor_for(result)
      return nil unless result.has_next?

      last_record = result.records.last
      return nil if last_record.nil?

      result.cursor_for(last_record)
    end
  end
end
