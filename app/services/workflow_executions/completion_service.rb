# frozen_string_literal: true

module WorkflowExecutions
  # Service used to complete a WorkflowExecution
  class CompletionService < BaseService
    def initialize(workflow_execution, wes_connection, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @wes_client = Integrations::Ga4ghWesApi::V1::Client.new(conn: wes_connection)
      @storage_service = ActiveStorage::Blob.service
    end

    def execute
      return false unless @workflow_execution.completed?

      output_base_path = @workflow_execution.blob_run_directory + '/output/'

      run_output_data = parse_base_output_file(output_base_path:)

      output_file_paths = get_output_file_paths(output_base_path:, run_output_data:)

      output_file_paths.each do |file_path|
        attach_output_file_to_model(file_path:)
      end

      @workflow_execution.state = 'finalized'

      @workflow_execution.save

      @workflow_execution
    end

    private

    def parse_base_output_file(output_base_path:)
      output_file_path = output_base_path + 'iridanext.output.json.gz'

      # TODO handle errors
      # not a gzip file
      # file doesn't exist
      # malformed json
      run_output_data = JSON.parse(
        ActiveSupport::Gzip.decompress(
          ActiveStorage::Blob.service.download(output_file_path)
        )
      )
    end

    def get_output_file_paths(output_base_path:, run_output_data:)
      run_output_data['files']['global'].map{
        |entry| output_base_path + entry['path']
      }
    end

    def attach_output_file_to_model(file_path:)
      Tempfile.open do |tempfile|
        # chunked download of blob file so mem doesn't get overwhelmed
        @storage_service.download(file_path) do |chunk|
          tempfile.write(chunk.force_encoding("UTF-8"))
        end
        tempfile.rewind
        # create new blob with file and attach
        @workflow_execution.outputs.attach(
          io: tempfile,
          filename:File.basename(file_path),
          checksum: compute_checksum_in_chunks(tempfile)
        )
      end
    end

    def compute_checksum_in_chunks(io)
      Digest::MD5.new.tap do |checksum|
        while chunk = io.read(5.megabytes)
          checksum << chunk
        end

        io.rewind
      end.base64digest
    end
  end
end
