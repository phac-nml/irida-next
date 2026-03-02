# frozen_string_literal: true

require 'test_helper'

module Pagination
  class ActiveRecordCursorAdapterTest < ActiveSupport::TestCase
    test 'returns first batch with next cursor, has_next_page, and total_count' do
      relation = ordered_project2_samples
      page = ActiveRecordCursorAdapter.new(relation).fetch(limit: 5)

      assert_equal 5, page.records.count
      assert page.has_next_page
      assert_not_nil page.next_cursor
      assert_equal relation.count, page.total_count
    end

    test 'second batch with after cursor does not overlap first batch' do
      relation = ordered_project2_samples
      adapter = ActiveRecordCursorAdapter.new(relation)
      first_page = adapter.fetch(limit: 5)
      second_page = adapter.fetch(limit: 5, after: first_page.next_cursor)

      assert_not_empty second_page.records
      assert_empty first_page.records.map(&:id) & second_page.records.map(&:id)
    end

    test 'final batch has has_next_page false and next_cursor nil' do
      relation = ordered_project2_samples
      adapter = ActiveRecordCursorAdapter.new(relation)

      first_page = adapter.fetch(limit: 7)
      second_page = adapter.fetch(limit: 7, after: first_page.next_cursor)
      final_page = adapter.fetch(limit: 7, after: second_page.next_cursor)

      assert_equal 6, final_page.records.count
      assert_not final_page.has_next_page
      assert_nil final_page.next_cursor
    end

    test 'raises invalid cursor error when cursor is invalid' do
      relation = ordered_project2_samples
      adapter = ActiveRecordCursorAdapter.new(relation)

      assert_raises ActiveRecordCursorPaginate::InvalidCursorError do
        adapter.fetch(limit: 5, after: 'invalid_cursor')
      end
    end

    test 'normalizes blank and null cursor values to nil' do
      relation = ordered_project2_samples
      adapter = ActiveRecordCursorAdapter.new(relation)
      first_page = adapter.fetch(limit: 5)
      blank_cursor_page = adapter.fetch(limit: 5, after: '')
      null_cursor_page = adapter.fetch(limit: 5, after: 'null')
      whitespace_cursor_page = adapter.fetch(limit: 5, after: "  \n")

      assert_equal first_page.records.map(&:id), blank_cursor_page.records.map(&:id)
      assert_equal first_page.records.map(&:id), null_cursor_page.records.map(&:id)
      assert_equal first_page.records.map(&:id), whitespace_cursor_page.records.map(&:id)
    end

    test 'clamps oversized and invalid limits to bounded server values' do
      relation = Sample.order(updated_at: :desc, id: :desc)
      adapter = ActiveRecordCursorAdapter.new(relation)

      oversized_limit_page = adapter.fetch(limit: 9_999)
      zero_limit_page = adapter.fetch(limit: 0)
      negative_limit_page = adapter.fetch(limit: -5)

      assert_equal ActiveRecordCursorAdapter::MAX_LIMIT, oversized_limit_page.records.count
      assert_equal ActiveRecordCursorAdapter::DEFAULT_LIMIT, zero_limit_page.records.count
      assert_equal ActiveRecordCursorAdapter::DEFAULT_LIMIT, negative_limit_page.records.count
    end

    private

    def ordered_project2_samples
      Sample.where(project_id: projects(:project2).id).order(updated_at: :desc, id: :desc)
    end
  end
end
