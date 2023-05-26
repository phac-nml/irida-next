# frozen_string_literal: true

# migration to add logidze logging column
class AddLogidzeToSamples < ActiveRecord::Migration[7.0]
  def change
    add_column :samples, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_samples, on: :samples
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_samples" on "samples";
        SQL
      end
    end
  end
end
