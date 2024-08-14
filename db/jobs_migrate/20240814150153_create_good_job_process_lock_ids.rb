# frozen_string_literal: true

# Migration to add process lock ids
class CreateGoodJobProcessLockIds < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.column_exists?(:good_jobs, :locked_by_id)
      end
    end

    add_column :good_jobs, :locked_by_id, :uuid # rubocop:disable Rails/BulkChangeTable
    add_column :good_jobs, :locked_at, :datetime
    add_column :good_job_executions, :process_id, :uuid
    add_column :good_job_processes, :lock_type, :integer, limit: 2
  end
end
