# frozen_string_literal: true

module BlobHelpers
  def make_and_upload_blob(filepath:, blob_run_directory:)
    output_json_file = File.new(filepath, 'r')
    output_json_file_blob = ActiveStorage::Blob.create_and_upload!(
      io: output_json_file,
      filename: File.basename(filepath)
    )
    output_json_file_input_key = generate_input_key(blob_run_directory, output_json_file_blob.filename, 'output/')

    compose_blob_with_custom_key(output_json_file_blob, output_json_file_input_key)
  end

  private

  def generate_input_key(run_dir, filename, prefix = '')
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
end
