# frozen_string_literal: true

module BlobTestHelpers
  def make_and_upload_blob(filepath:, blob_run_directory:, gzip: false) # rubocop:disable Metrics/MethodLength
    output_json_file = File.new(filepath, 'r')

    Tempfile.open do |tempfile|
      if gzip
        tempfile.write(ActiveSupport::Gzip.compress(output_json_file.read).force_encoding('UTF-8'))
        filepath = "#{filepath}.gz"
      else
        tempfile.write(output_json_file.read.force_encoding('UTF-8'))
      end
      tempfile.rewind
      @output_json_file_blob = ActiveStorage::Blob.create_and_upload!(
        io: tempfile,
        filename: File.basename(filepath)
      )
    end

    output_json_file_input_key = generate_input_key(blob_run_directory, @output_json_file_blob.filename, 'output/')
    compose_blob_with_custom_key(@output_json_file_blob, output_json_file_input_key)
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
