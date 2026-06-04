# frozen_string_literal: true

# View helpers for attachment upload Stimulus data attributes.
module AttachmentsHelper
  def attachment_upload_fastq_pairing_data_attributes
    { attachment_upload_fastq_pairing_patterns_value: Attachment.fastq_pairing_filename_patterns }
  end
end
