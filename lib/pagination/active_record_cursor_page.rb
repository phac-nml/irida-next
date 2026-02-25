# frozen_string_literal: true

module Pagination
  # Cursor pagination response contract used by non-GraphQL table paths.
  class ActiveRecordCursorPage
    attr_reader :records, :next_cursor, :has_next_page, :total_count

    def initialize(records:, next_cursor:, has_next_page:, total_count:)
      @records = records
      @next_cursor = next_cursor
      @has_next_page = has_next_page
      @total_count = total_count
    end
  end
end
