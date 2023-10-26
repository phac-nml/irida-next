# frozen_string_literal: true

# Validator for Attachment checksum
class AttachmentChecksumValidator < ActiveModel::Validator
  def validate(record)
    return if record.file.checksum.blank?

    klass = record.class

    # add error if another Attachment associated with the Attachable exists with the same checksum
    if klass.joins(:file_blob)
            .where.not(id: record.id)
            .exists?(attachable_id: record.attachable_id,
                     attachable_type: record.attachable_type,
                     deleted_at: nil,
                     file_blob: { checksum: record.file.checksum })
      record.errors.add(:file, :checksum_uniqueness)
    end
  end
end
