# frozen_string_literal: true

# Update metadata index for attachments and samples to be on lower case
class UpdateMetadataIndexes < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/MethodLength
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          DROP INDEX index_attachments_on_metadata;
          CREATE INDEX index_attachments_on_metadata_ci ON attachments USING GIN ((LOWER(metadata::text)::jsonb));

          DROP INDEX index_samples_on_metadata;
          CREATE INDEX index_samples_on_metadata_ci ON samples USING GIN ((LOWER(metadata::text)::jsonb));
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          DROP INDEX index_attachments_on_metadata_ci;
          DROP INDEX index_samples_on_metadata_ci;
        SQL
        add_index :attachments, :metadata, using: :gin
        add_index :samples, :metadata, using: :gin
      end
    end
  end
end
