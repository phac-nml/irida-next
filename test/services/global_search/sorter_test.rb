# frozen_string_literal: true

require 'test_helper'

module GlobalSearch
  class SorterTest < ActiveSupport::TestCase
    def build_result(type:, score_bucket:, updated_at:, record_id: SecureRandom.uuid)
      GlobalSearch::Result.new(
        type:,
        record_id:,
        title: "#{type} result",
        subtitle: '',
        url: "/#{type}/#{record_id}",
        match_tags: [],
        score_bucket:,
        updated_at:
      )
    end

    test 'best_match sorts by score bucket ascending' do
      exact = build_result(type: 'projects', score_bucket: 1, updated_at: 1.day.ago)
      fuzzy = build_result(type: 'projects', score_bucket: 6, updated_at: Time.current)

      results = GlobalSearch::Sorter.new([fuzzy, exact], sort: 'best_match', selected_types: %w[projects]).call

      assert_equal 1, results.first.score_bucket
      assert_equal 6, results.last.score_bucket
    end

    test 'most_recent sorts by updated_at descending' do
      old = build_result(type: 'projects', score_bucket: 1, updated_at: 2.days.ago)
      recent = build_result(type: 'projects', score_bucket: 6, updated_at: 1.hour.ago)

      results = GlobalSearch::Sorter.new([old, recent], sort: 'most_recent', selected_types: %w[projects]).call

      assert_equal recent.record_id, results.first.record_id
    end

    test 'most_recent with multiple types applies soft diversity' do
      now = Time.current
      projects = 5.times.map { |i| build_result(type: 'projects', score_bucket: 3, updated_at: now - i.minutes) }
      group = build_result(type: 'groups', score_bucket: 3, updated_at: now - 6.minutes)

      results = GlobalSearch::Sorter.new(
        projects + [group],
        sort: 'most_recent',
        selected_types: %w[projects groups]
      ).call

      # Diversity should prevent more than 4 consecutive same-type results in the head
      first_10_types = results.first(10).map(&:type)
      max_streak = first_10_types.chunk_while { |a, b| a == b }.map(&:length).max
      assert_operator max_streak, :<=, 4
    end

    test 'most_recent with single type skips diversity' do
      now = Time.current
      results_input = 5.times.map { |i| build_result(type: 'projects', score_bucket: 3, updated_at: now - i.minutes) }

      results = GlobalSearch::Sorter.new(results_input, sort: 'most_recent', selected_types: %w[projects]).call

      assert_equal 5, results.size
      assert(results.all? { |r| r.type == 'projects' })
    end

    test 'defaults to best_match for unknown sort' do
      exact = build_result(type: 'projects', score_bucket: 1, updated_at: 1.day.ago)
      fuzzy = build_result(type: 'projects', score_bucket: 6, updated_at: Time.current)

      results = GlobalSearch::Sorter.new([fuzzy, exact], sort: 'unknown', selected_types: %w[projects]).call

      assert_equal 1, results.first.score_bucket
    end
  end
end
