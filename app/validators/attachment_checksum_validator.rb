# frozen_string_literal: true

# Validator for Attachment checksum
class AttachmentChecksumValidator < ActiveModel::Validator
  def validate(record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return if record.file.checksum.blank?

    klass = record.class

    # add error if another Attachment associated with the Attachable exists with the same checksum
    # no error occurs if the files have same name but different checksum or same checksum but different filenames
    if klass.joins(:file_blob)
            .where.not(id: record.id)
            .exists?(attachable_id: record.attachable_id,
                     attachable_type: record.attachable_type,
                     deleted_at: nil,
                     file_blob: { checksum: record.file.checksum, filename: record.file.filename.to_s })

      record.errors.add(:file, :checksum_uniqueness)
    end
  end
end
