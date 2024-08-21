# frozen_string_literal: true

# migration to update namespace metadata_summary after downcasing metadata keys
class FixMetadataSummaryAfterDowncasingMetadataKeys < ActiveRecord::Migration[7.2]
  def up
    Namespace.all.each do |namespace|
      namespace.metadata_summary = namespace.metadata_summary.transform_keys { |key| key.to_s.downcase }
      namespace.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
