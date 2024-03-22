# frozen_string_literal: true

module WorkflowExecutions
  # Service used to complete a WorkflowExecution
  class CompletionService < BaseService
    include BlobHelper

    def initialize(workflow_execution, params = {})
      super(workflow_execution.submitter, params)

      @workflow_execution = workflow_execution
      @storage_service = ActiveStorage::Blob.service
      @attachable_blobs_tuple_list = []
      @output_base_path = "#{@workflow_execution.blob_run_directory}/output/"
    end

    def execute
      return false unless @workflow_execution.completed?

      run_output_data = download_decompress_parse_gziped_json("#{@output_base_path}iridanext.output.json.gz")

      # global run output files
      output_global_file_paths = get_output_global_file_paths(run_output_data:)
      process_global_file_paths(output_global_file_paths:)

      # per sample output files
      output_samples_file_paths = get_output_samples_file_paths(run_output_data:)
      process_sample_file_paths(output_samples_file_paths:)

      # per sample metadata
      process_samples_metadata(run_output_data:)

      # attach blob lists to attachables
      attach_blobs_to_attachables

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

    def process_global_file_paths(output_global_file_paths:)
      # Handle ouput files for workflow execution
      global_file_blob_list = []
      output_global_file_paths&.each do |blob_file_path|
        global_file_blob_list.append(download_and_make_new_blob(blob_file_path:))
      end
      @attachable_blobs_tuple_list.append({ attachable: @workflow_execution,
                                            blob_id_list: global_file_blob_list })
    end

    def process_sample_file_paths(output_samples_file_paths:)
      # Handle output files for samples workflow execution
      output_samples_file_paths&.each do |sample_file_paths_tuple| # :sample_puid, :data_paths
        sample_file_blob_list = []
        sample_file_paths_tuple[:data_paths]&.each do |blob_file_path|
          sample_file_blob_list.append(download_and_make_new_blob(blob_file_path:))
        end

        samples_workflow_execution = get_samples_workflow_executions_by_sample_puid(
          puid: sample_file_paths_tuple[:sample_puid]
        )

        @attachable_blobs_tuple_list.append({ attachable: samples_workflow_execution,
                                              blob_id_list: sample_file_blob_list })
      end
    end

    def get_samples_workflow_executions_by_sample_puid(puid:)
      @workflow_execution.samples_workflow_executions \
                         .joins(:sample) \
                         .where(sample: { puid: }) \
                         .first
    end

    def attach_blobs_to_attachables
      return if @attachable_blobs_tuple_list.empty?

      @attachable_blobs_tuple_list&.each do |tuple| # :attachable, :blob_id_list
        Attachments::CreateService.new(
          current_user, tuple[:attachable], { files: tuple[:blob_id_list] }
        ).execute
      end
    end

    def process_samples_metadata(run_output_data:)
      return nil unless run_output_data['metadata']['samples']

      run_output_data['metadata']['samples']&.each do |sample_puid, sample_metadata|
        samples_workflow_execution = get_samples_workflow_executions_by_sample_puid(puid: sample_puid)
        samples_workflow_execution.metadata = sample_metadata
        samples_workflow_execution.save!
      end
    end
  end
end
