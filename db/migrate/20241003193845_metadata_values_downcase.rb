# frozen_string_literal: true

# Update all metadata values to be lower case
class MetadataValuesDowncase < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE samples SET metadata = LOWER(metadata::text)::jsonb;
        SQL
      end
    end
  end
end
