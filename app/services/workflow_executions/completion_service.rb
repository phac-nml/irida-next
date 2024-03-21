# frozen_string_literal: true

module WorkflowExecutions
  # Service used to complete a WorkflowExecution
  class CompletionService < BaseService
    include BlobHelper

    def initialize(workflow_execution, params = {})
      super(workflow_execution.submitter, params)

      @workflow_execution = workflow_execution
      @storage_service = ActiveStorage::Blob.service
      @file_blob_list = []
      @output_base_path = "#{@workflow_execution.blob_run_directory}/output/"
    end

    def execute
      return false unless @workflow_execution.completed?

      run_output_data = download_decompress_parse_gziped_json("#{@output_base_path}iridanext.output.json.gz")
      attachable_blobs_tuple_list = []

      # global run output files
      output_global_file_paths = get_output_global_file_paths(run_output_data:)
      global_file_blob_list = []
      output_global_file_paths&.each do |blob_file_path|
        global_file_blob_list.append(download_and_make_new_blob(blob_file_path:))
      end
      attachable_blobs_tuple_list.append({ attachable: @workflow_execution, blob_id_list: global_file_blob_list })

      # # per sample output files
      # output_samples_file_paths = get_output_samples_file_paths(run_output_data:)
      # output_samples_file_paths&.each do |sample_file_paths_tupple|
      #   # todo replace this with a better way of keeping track of files
      #   @file_blob_list = []
      #   sample_file_paths_tupple[:file_paths]&.each do |file_path|
      #     download_and_make_blob(file_path:)
      #   end
      #   #todo solve for this line
      #   swe = get_samples_workflow_executions_somehow_todo(sample_file_paths_tupple[:sample_name, @workflow_execution])
      #   unless @file_blob_list.empty?
      #     #todo shouldnt have independant attachment creation for
      #     Attachments::CreateService.new(
      #       current_user, swe, { files: @file_blob_list }
      #     ).execute
      #   end
      # end

      # attach blob lists to attachables
      unless attachable_blobs_tuple_list.empty?
        attachable_blobs_tuple_list&.each do |tuple|
          Attachments::CreateService.new(
            current_user, tuple[:attachable], { files: tuple[:blob_id_list] }
          ).execute
        end
      end

      @workflow_execution.state = 'finalized'

      @workflow_execution.save

      @workflow_execution
    end

    private

    def get_output_global_file_paths(run_output_data:)
      return nil unless run_output_data['files']['global']

      #todo put data path mapping in it's own method
      run_output_data['files']['global'].map { |entry| @output_base_path + entry['path'] }
    end

    def get_output_samples_file_paths(run_output_data:)
      return nil unless run_output_data['files']['samples']

      samples_paths = []
      run_output_data['files']['samples'].each do |sample_name, sample_data_paths|
        data_paths = sample_data_paths.map { |entry| @output_base_path + entry['path'] }

        samples_paths.append({ sample_name:, data_paths: })
      end
      samples_paths
    end
  end
end
