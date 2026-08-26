# frozen_string_literal: true

# This migration adds an index to the samples table for the latest transfer job ID.
class AddLatestTransferJobIdIndexToSamples < ActiveRecord::Migration[8.1]
  def change
    # We use a standard btree index because we are extracting a single scalar string value (->>)
    add_index :samples,
              "((log_data -> 'h' -> -1 -> 'm' ->> 'transfer_job_id'))",
              name: 'index_samples_on_latest_transfer_job_id'
  end
end
