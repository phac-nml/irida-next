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
      attachable_blobs_tuple_list.append({ attachable: @workflow_execution,
                                           blob_id_list: global_file_blob_list })

      # per sample output files
      output_samples_file_paths = get_output_samples_file_paths(run_output_data:)
      output_samples_file_paths&.each do |sample_file_paths_tuple| # :sample_puid, :data_paths
        sample_file_blob_list = []
        sample_file_paths_tuple[:data_paths]&.each do |blob_file_path|
          sample_file_blob_list.append(download_and_make_new_blob(blob_file_path:))
        end

        samples_workflow_execution = \
          @workflow_execution.samples_workflow_executions \
                             .joins(:sample) \
                             .where(sample: { puid: sample_file_paths_tuple[:sample_puid] }) \
                             .first

        attachable_blobs_tuple_list.append({ attachable: samples_workflow_execution,
                                             blob_id_list: sample_file_blob_list })
      end

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

      get_path_mapping(run_output_data['files']['global'])
    end

    def get_output_samples_file_paths(run_output_data:)
      return nil unless run_output_data['files']['samples']

      samples_paths = []
      run_output_data['files']['samples'].each do |sample_puid, sample_data_paths|
        data_paths = get_path_mapping(sample_data_paths)

        samples_paths.append({ sample_puid:, data_paths: })
      end
      samples_paths
    end

    def get_path_mapping(data_paths)
      data_paths.map { |entry| @output_base_path + entry['path'] }
    end
  end
end
