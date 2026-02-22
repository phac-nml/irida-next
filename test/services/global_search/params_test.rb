# frozen_string_literal: true

require 'test_helper'

module GlobalSearch
  class ParamsTest < ActiveSupport::TestCase
    test 'query strips whitespace' do
      params = GlobalSearch::Params.new(q: '  hello  ')
      assert_equal 'hello', params.query
    end

    test 'query returns empty string when nil' do
      params = GlobalSearch::Params.new({})
      assert_equal '', params.query
    end

    test 'types returns defaults when none provided' do
      params = GlobalSearch::Params.new({})
      assert_equal %w[projects groups workflow_executions samples data_exports], params.types
    end

    test 'types filters to valid values' do
      params = GlobalSearch::Params.new(types: %w[projects invalid_type samples])
      assert_equal %w[projects samples], params.types
    end

    test 'types returns defaults when all provided are invalid' do
      params = GlobalSearch::Params.new(types: %w[invalid])
      assert_equal %w[projects groups workflow_executions samples data_exports], params.types
    end

    test 'match_sources returns defaults when none provided' do
      params = GlobalSearch::Params.new({})
      assert_equal %w[identifier name], params.match_sources
    end

    test 'match_sources includes metadata when requested' do
      params = GlobalSearch::Params.new(match_sources: %w[name metadata])
      assert_equal %w[name metadata], params.match_sources
    end

    test 'sort defaults to best_match' do
      params = GlobalSearch::Params.new({})
      assert_equal 'best_match', params.sort
    end

    test 'sort accepts most_recent' do
      params = GlobalSearch::Params.new(sort: 'most_recent')
      assert_equal 'most_recent', params.sort
    end

    test 'sort rejects invalid values' do
      params = GlobalSearch::Params.new(sort: 'invalid')
      assert_equal 'best_match', params.sort
    end

    test 'per_type_limit uses suggest defaults when suggest is true' do
      params = GlobalSearch::Params.new(suggest: true)
      assert_equal 5, params.per_type_limit
    end

    test 'per_type_limit uses index defaults when suggest is false' do
      params = GlobalSearch::Params.new(suggest: false)
      assert_equal 20, params.per_type_limit
    end

    test 'per_type_limit clamps to maximum' do
      params = GlobalSearch::Params.new(per_type_limit: 999)
      assert_equal 50, params.per_type_limit
    end

    test 'limit clamps to maximum' do
      params = GlobalSearch::Params.new(limit: 999)
      assert_equal 200, params.limit
    end

    test 'filters parses valid dates' do
      params = GlobalSearch::Params.new(created_from: '2024-01-15', created_to: '2024-06-30')
      filters = params.filters

      assert_equal Date.new(2024, 1, 15).beginning_of_day, filters[:created_from]
      assert_equal Date.new(2024, 6, 30).end_of_day, filters[:created_to]
    end

    test 'filters returns nil for invalid dates' do
      params = GlobalSearch::Params.new(created_from: 'not-a-date')
      assert_nil params.filters[:created_from]
    end

    test 'filters returns nil for blank dates' do
      params = GlobalSearch::Params.new(created_from: '')
      assert_nil params.filters[:created_from]
    end
  end
end
