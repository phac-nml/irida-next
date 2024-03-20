# frozen_string_literal: true

module WorkflowExecutions
  # Service used to complete a WorkflowExecution
  class CompletionService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)

      @workflow_execution = workflow_execution
      @storage_service = ActiveStorage::Blob.service
      @file_blob_list = []
      @output_base_path = "#{@workflow_execution.blob_run_directory}/output/"
    end

    def execute
      return false unless @workflow_execution.completed?

      run_output_data = parse_base_output_file

      output_file_paths = get_output_file_paths(run_output_data:)

      output_file_paths&.each do |file_path|
        download_and_make_blob(file_path:)
      end

      unless @file_blob_list.empty?
        Attachments::CreateService.new(
          current_user, @workflow_execution, { files: @file_blob_list }
        ).execute
      end

      @workflow_execution.state = 'finalized'

      @workflow_execution.save

      @workflow_execution
    end

    private

    def parse_base_output_file
      JSON.parse(
        ActiveSupport::Gzip.decompress(
          ActiveStorage::Blob.service.download("#{@output_base_path}iridanext.output.json.gz")
        )
      )
    end

    def get_output_file_paths(run_output_data:)
      return nil unless run_output_data['files']['global']

      run_output_data['files']['global'].map { |entry| @output_base_path + entry['path'] }
    end

    def download_and_make_blob(file_path:)
      Tempfile.open do |tempfile|
        # chunked download of blob file so mem doesn't get overwhelmed
        @storage_service.download(file_path) do |chunk|
          tempfile.write(chunk.force_encoding('UTF-8'))
        end
        tempfile.rewind
        file_blob = ActiveStorage::Blob.create_and_upload!(
          io: tempfile,
          filename: File.basename(file_path)
        )
        @file_blob_list.append(file_blob.signed_id)
      end
    end
  end
end
