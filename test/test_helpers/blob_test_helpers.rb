# frozen_string_literal: true

module BlobTestHelpers
  include BlobHelper

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

    output_json_file_input_key = generate_input_key(
      run_dir: blob_run_directory,
      filename: @output_json_file_blob.filename,
      prefix: 'output/'
    )
    compose_blob_with_custom_key(@output_json_file_blob, output_json_file_input_key)
  end
end
