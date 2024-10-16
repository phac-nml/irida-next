# frozen_string_literal: true

# Update all metadata values to be text
class UpdateMetadataValuesToText < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          update samples set metadata = (select jsonb_object_agg(key, value) from jsonb_each_text(metadata)) where metadata != '{}';
        SQL
      end
    end
  end
end
