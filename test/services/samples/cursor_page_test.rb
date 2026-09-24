# frozen_string_literal: true

require 'test_helper'

module Samples
  class CursorPageTest < ActiveSupport::TestCase
    setup do
      @project = projects(:project1)
      @timestamp = Time.utc(2026, 9, 24, 12, 0, 0)
      @samples = Array.new(9) do |index|
        Sample.create!(project: @project, name: "Cursor sample #{index + 1}",
                       created_at: @timestamp + Rational(index / 2, 1_000_000),
                       updated_at: @timestamp + Rational(index, 1_000_000),
                       attachments_updated_at: index < 4 ? @timestamp : nil,
                       metadata: metadata_for(index))
      end
      @scope = Sample.where(id: @samples.map(&:id))
    end

    test 'matches existing native sort order in both directions across all pages' do
      %w[name puid created_at updated_at attachments_updated_at].product(%w[asc desc]).each do |column, direction|
        query = build_query("#{column} #{direction}")

        assert_equal query.results.pluck(:id), traverse(query).map(&:id), "#{column} #{direction}"
      end
    end

    test 'matches metadata numeric collation with empty values and multiple pages of missing values' do
      %w[asc desc].each do |direction|
        query = build_query("metadata_field with spaces #{direction}")

        assert_equal query.results.pluck(:id), traverse(query).map(&:id)
      end

      records = traverse(build_query('metadata_field with spaces asc'))
      assert_equal(['', '2', '2', '10'], records.first(4).map { |record| record.metadata['field with spaces'] })
    end

    test 'quotes metadata field names when building the projection' do
      field = "field's value"
      @samples.first.update!(metadata: { field => '10' })
      @samples.second.update!(metadata: { field => '2' })
      query = build_query("metadata.#{field} asc")

      assert_equal query.results.pluck(:id), traverse(query).map(&:id)
    end

    test 'preserves nullable name ordering without conflating null and empty strings' do
      @samples.first.update_column(:name, nil) # rubocop:disable Rails/SkipsModelValidations
      @samples.second.update_column(:name, '') # rubocop:disable Rails/SkipsModelValidations

      %w[asc desc].each do |direction|
        query = build_query("name #{direction}")

        assert_equal query.results.pluck(:id), traverse(query).map(&:id)
      end
    end

    test 'preserves timestamp microseconds through the signed cursor' do
      %w[asc desc].each do |direction|
        query = build_query("updated_at #{direction}")
        records = traverse(query, limit: 1)

        assert_equal query.results.pluck(:id), records.map(&:id)
        assert_equal 9, records.map(&:updated_at).uniq.length
      end
    end

    test 'applies the existing quick search and advanced filter before pagination' do
      params = { sort: 'puid asc', name_or_puid_cont: 'Cursor sample',
                 groups_attributes: { '0' => { conditions_attributes: {
                   '0' => { field: 'metadata.field with spaces', operator: '=', value: '2' }
                 } } } }
      query = build_query(params.delete(:sort), **params)

      assert_equal query.results.pluck(:id), traverse(query, query_params: params).map(&:id)
      assert_equal 2, traverse(query, query_params: params).length
    end

    test 'keeps the supplied project boundary even when the query has a broader scope' do
      query = Sample::Query.new(project_ids: [@project.id, projects(:project2).id], sort: 'puid asc')
      records = traverse(query)

      assert(records.all? { |record| record.project_id == @project.id })
    end

    test 'returns empty and terminal pages without a next cursor' do
      query = build_query('name asc', name_or_puid_cont: 'no-matching-sample')
      result = page(query)

      assert_empty result.records
      assert_nil result.next_cursor
      assert_equal 0, result.row_offset
      assert_nil page(build_query('name asc'), limit: 100).next_cursor
    end

    test 'returns the next global row offset and preloaded project associations' do
      query = build_query('name asc')
      first = page(query)
      second = page(query, cursor: first.next_cursor)

      assert_equal 0, first.row_offset
      assert_equal 2, second.row_offset
      assert_equal 2, second.limit
      assert(second.records.all? { |record| record.association(:project).loaded? })
      assert(second.records.all? { |record| record.project.association(:namespace).loaded? })
    end

    test 'rejects malformed or tampered cursors' do
      query = build_query('name asc')
      cursor = page(query).next_cursor

      ['', 'not-a-cursor', "#{cursor}tampered"].each do |value|
        assert_raises(CursorPage::InvalidCursor) { page(query, cursor: value) }
      end
    end

    test 'binds the cursor to project query sort and effective limit' do
      query = build_query('name asc')
      cursor = page(query, query_params: { sort: 'name asc' }).next_cursor

      assert_raises(CursorPage::InvalidCursor) do
        page(query, cursor:, query_params: { sort: 'name asc' }, project: projects(:project2))
      end
      assert_raises(CursorPage::InvalidCursor) do
        page(query, cursor:, query_params: { sort: 'name asc', name_or_puid_cont: 'changed' })
      end
      assert_raises(CursorPage::InvalidCursor) do
        page(build_query('name desc'), cursor:, query_params: { sort: 'name asc' })
      end
      assert_raises(CursorPage::InvalidCursor) do
        page(query, cursor:, query_params: { sort: 'name asc' }, limit: 3)
      end
    end

    test 'canonicalizes nested query keys without changing array order' do
      query = build_query('name asc')
      first_params = { sort: 'name asc', groups: { b: %w[first second], a: 'value' } }
      second_params = { 'groups' => { 'a' => 'value', 'b' => %w[first second] }, 'sort' => 'name asc' }
      cursor = page(query, query_params: first_params).next_cursor

      assert_equal 2, page(query, cursor:, query_params: second_params).row_offset
      second_params['groups']['b'].reverse!
      assert_raises(CursorPage::InvalidCursor) { page(query, cursor:, query_params: second_params) }
    end

    test 'normalizes page limits and rejects invalid queries' do
      query = build_query('name asc')

      assert_equal 100, page(query, limit: 500).limit
      [nil, 0, -1, 'invalid'].each { |limit| assert_equal 20, page(query, limit:).limit }
      assert_equal 1, page(query, limit: '1').limit
      assert_raises(CursorPage::InvalidQuery) { page(build_query('not_a_column desc')) }
      assert_raises(CursorPage::InvalidQuery) { page(build_query('name invalid')) }
    end

    test 'reads the configured default and maximum at initialization' do
      query = build_query('name asc')
      Pagy::OPTIONS.stubs(:fetch).with(:limit).returns(3)
      Pagy::OPTIONS.stubs(:fetch).with(:max_limit).returns(4)

      assert_equal 3, CursorPage.new(query:, project: @project, query_params: {}).call.limit
      assert_equal 3, page(query, limit: nil).limit
      assert_equal 3, page(query, limit: 'invalid').limit
      assert_equal 4, page(query, limit: 100).limit
      assert_equal 2, page(query, limit: 2).limit
    end

    test 'fetches initial and continuation pages without count or offset queries' do
      query = build_query('updated_at desc')
      statements = []
      subscriber = ->(_name, _start, _finish, _id, payload) { statements << payload[:sql] }

      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
        first = page(query)
        page(query, cursor: first.next_cursor)
      end

      selects = statements.grep(/SELECT/i)
      assert(selects.any? { |sql| sql.include?('pvc_cursor_value') })
      assert selects.none? { |sql| sql.match?(/\bCOUNT\s*\(|\bOFFSET\b/i) }, selects.join("\n")
    end

    private

    def metadata_for(index)
      value = ['10', '2', '2', ''][index]
      return {} if value.nil? && index.even?

      { 'field with spaces' => value }
    end

    def build_query(sort, **params)
      Sample::Query.new(project_ids: [@project.id], scope: @scope, sort:, **params)
    end

    def page(query, query_params: {}, project: @project, **)
      CursorPage.new(query:, project:, query_params:, limit: 2, **).call
    end

    def traverse(query, **)
      records = []
      cursor = nil
      30.times do
        result = page(query, cursor:, **)
        assert_equal records.length, result.row_offset
        records.concat(result.records)
        cursor = result.next_cursor
        return records unless cursor
      end
      flunk 'Cursor traversal did not terminate'
    end
  end
end
