# frozen_string_literal: true

# Validator for Attachment checksum
class AttachmentChecksumValidator < ActiveModel::Validator
  def validate(record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return if record.file.checksum.blank?

    klass = record.class

    # add error if another Attachment associated with the Attachable exists with the same checksum

    # checks if file has same checksum and name (no error if same contents but different name)
    if klass.joins(:file_blob)
            .where.not(id: record.id)
            .exists?(attachable_id: record.attachable_id,
                     attachable_type: record.attachable_type,
                     deleted_at: nil,
                     file_blob: { checksum: record.file.checksum, filename: record.file.filename.to_s }) ||
       #  checks for same filename
       klass.joins(:file_blob)
            .where.not(id: record.id)
            .exists?(attachable_id: record.attachable_id,
                     attachable_type: record.attachable_type,
                     deleted_at: nil,
                     file_blob: { filename: record.file.filename.to_s })

      record.errors.add(:file, :checksum_uniqueness)
    end
  end
end
