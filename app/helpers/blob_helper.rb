# frozen_string_literal: true

# Blob service helper to handle interactions with blobs
module BlobHelper
  def generate_run_directory
    ActiveStorage::Blob.generate_unique_secure_token
  end

  def generate_input_key(run_dir:, filename:, prefix:)
    format('%<run_dir>s/%<prefix>s%<filename>s', run_dir:, filename:, prefix:)
  end

  def compose_blob_with_custom_key(blob, key)
    ActiveStorage::Blob.new(
      key:,
      filename: blob.filename,
      byte_size: blob.byte_size,
      checksum: blob.checksum,
      content_type: blob.content_type
    ).tap do |copied_blob|
      copied_blob.compose([blob.key])
      copied_blob.save!
    end
  end

  def download_decompress_parse_gziped_json(blob_file_path)
    JSON.parse(
      ActiveSupport::Gzip.decompress(
        ActiveStorage::Blob.service.download(blob_file_path)
      )
    )
  end

  def download_and_make_new_blob(blob_file_path:)
    blob_id = nil
    Tempfile.open do |tempfile|
      # chunked download of blob file so mem doesn't get overwhelmed
      ActiveStorage::Blob.service.download(blob_file_path) do |chunk|
        tempfile.write(chunk.force_encoding('UTF-8'))
      end
      tempfile.rewind
      file_blob = ActiveStorage::Blob.create_and_upload!(
        io: tempfile,
        filename: File.basename(blob_file_path)
      )
      blob_id = file_blob.signed_id
    end

    blob_id
  end
end
