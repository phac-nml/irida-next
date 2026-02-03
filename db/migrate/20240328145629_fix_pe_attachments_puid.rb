# frozen_string_literal: true

# updates reverse pe attachment puid to match forward pe attachment puid
class FixPeAttachmentsPuid < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      WITH forward_attachments AS (
        SELECT id, puid, (metadata->>'associated_attachment_id')::uuid as associated_attachment_id
        FROM attachments
        WHERE metadata @> '{"type":"pe","direction":"forward"}'
        OR metadata @> '{"type":"illumina_pe","direction":"forward"}'
      )
      UPDATE attachments
      SET puid = fa.puid
      FROM forward_attachments fa
      WHERE attachments.id = fa.associated_attachment_id AND attachments.puid != fa.puid;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
