# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    # Regression/validation test proving the atomic implementation is safe against races where a
    # concurrent writer commits an analysis-owned value for a field while this update is in flight,
    # even though it deliberately does NOT acquire an explicit row lock. Its "is this writable"
    # decision is made via scalar subqueries correlated directly to the single row being updated (no
    # separate join/CTE scan of `samples`): PostgreSQL's EvalPlanQual conflict resolution substitutes
    # the latest committed tuple for this row throughout the whole statement, so a blocked writer
    # sees fresh data once it unblocks. See BaseSampleMetadataUpdateService#atomic_update_sql.
    #
    # This requires genuine concurrent PostgreSQL connections with real, committed row locks.
    # Transactional test fixtures wrap each test in an open, uncommitted transaction on the test's
    # own connection; a second connection's `SELECT ... FOR UPDATE` on the same row would then block
    # forever waiting for a lock that is never released within the test, deadlocking the test.
    # Transactional tests are disabled here and the sample is cleaned up manually.
    class AtomicUpdateConcurrencyTest < ActiveSupport::TestCase
      self.use_transactional_tests = false

      def setup
        @user = users(:john_doe)
        @project = projects(:project31)
        @sample = Sample.create!(
          project: @project,
          name: "atomic-concurrency-#{SecureRandom.hex(4)}",
          metadata: { 'field1' => 'initial' },
          metadata_provenance: { 'field1' => { source: 'user', id: @user.id, updated_at: Time.current } }
        )
      end

      def teardown
        @sample&.destroy
      end

      test 'does not let a concurrent user update overwrite metadata committed as analysis-owned while blocked' do
        lock_acquired = Queue.new

        writer_thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            connection.transaction do
              connection.execute("SELECT id FROM samples WHERE id = #{connection.quote(@sample.id)} FOR UPDATE")
              lock_acquired << true
              # Hold the lock long enough for the main thread's update below to start and block on it.
              sleep 1
              connection.execute(<<~SQL.squish)
                UPDATE samples
                SET metadata = jsonb_set(metadata, ARRAY['field1'], '"analysis_committed_value"'::jsonb),
                    metadata_provenance = jsonb_set(metadata_provenance, ARRAY['field1','source'], '"analysis"'::jsonb)
                WHERE id = #{connection.quote(@sample.id)}
              SQL
            end
          end
        end

        lock_acquired.pop

        result = UpdateService.new(
          @project,
          @sample,
          @user,
          { 'metadata' => { 'field1' => 'user_attempted_value' },
            'metadata_update_implementation' => 'atomic' }
        ).execute

        writer_thread.join

        assert_equal ['field1'], result[:not_updated]

        @sample.reload
        assert_equal 'analysis_committed_value', @sample.metadata['field1']
        assert_equal 'analysis', @sample.metadata_provenance['field1']['source']
      end
    end
  end
end
