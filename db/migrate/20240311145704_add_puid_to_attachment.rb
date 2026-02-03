# frozen_string_literal: true

# Migration to add Persistent Unique Identifier column to Attachment model
class AddPuidToAttachment < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    add_column :attachments, :puid, :string

    reversible do |dir|
      dir.up do
        Attachment
          .with_deleted
          .where('metadata @> ? OR metadata @> ?', { 'type' => 'pe', 'direction' => 'forward' }.to_json,
                 { 'type' => 'illumina_pe', 'direction' => 'forward' }.to_json).each do |att|
          puid = Irida::PersistentUniqueId.generate(att, time: att.created_at)
          execute <<~SQL.squish
            UPDATE attachments SET puid = '#{puid}' WHERE id in ('#{att.id}', '#{att.metadata['associated_attachment_id']}')
          SQL
        end
        Attachment
          .with_deleted
          .where('NOT metadata @> ? AND NOT metadata @> ?', { 'type' => 'pe' }.to_json,
                 { 'type' => 'illumina_pe' }.to_json).each do |att|
          puid = Irida::PersistentUniqueId.generate(att, time: att.created_at)
          execute <<~SQL.squish
            UPDATE attachments SET puid = '#{puid}' WHERE id = '#{att.id}'
          SQL
        end
        change_column :attachments, :puid, :string, null: false
      end
    end

    add_index :attachments, :puid, unique: false
  end
end
