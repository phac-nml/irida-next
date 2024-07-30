# frozen_string_literal: true

# migration to update all metadata keys to be downcased
# outputs a list of sample puid's which could not be downcased because of duplicate keys
class MetadataKeysDowncase < ActiveRecord::Migration[7.1]
  @fail_list = []

  def up
    migrate_sample_metadata
    put_failed_migration_list
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def migrate_sample_metadata
    Sample.all.each do |sample|
      next if duplicate_key?(sample.metadata, sample.puid) ||
              duplicate_key?(sample.metadata_provenance, sample.puid)

      update_metadata(sample)
    end
  end

  def duplicate_key?(metadata_hash, puid)
    keys = metadata_hash.map { |key, _| key.to_s.downcase }

    res = keys.uniq.length != keys.length

    @fail_list.append(puid) if res

    res
  end

  def update_metadata(sample)
    sample.metadata = sample.metadata.transform_keys { |key| key.to_s.downcase }
    sample.metadata_provenance = sample.metadata_provenance.transform_keys { |key| key.to_s.downcase }
    sample.save!
  end

  def put_failed_migration_list
    @fail_list.each do |puid|
      puts "Metadata Downcase Migration skipped Sample #{puid}"
    end
  end
end
