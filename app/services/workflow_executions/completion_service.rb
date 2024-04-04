# frozen_string_literal: true

module WorkflowExecutions
  # Service used to complete a WorkflowExecution
  class CompletionService < BaseService # rubocop:disable Metrics/ClassLength
    include BlobHelper
    include MetadataHelper

    def initialize(workflow_execution, params = {})
      super(workflow_execution.submitter, params)

      @workflow_execution = workflow_execution
      @storage_service = ActiveStorage::Blob.service
      @attachable_blobs_tuple_list = []
      @output_base_path = "#{@workflow_execution.blob_run_directory}/output/"
    end

    def execute
      return false unless @workflow_execution.completing?

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

      # put attachments and metadata onto samples
      if @workflow_execution.update_samples?
        merge_metadata_onto_samples
        put_output_attachments_onto_samples
      end

      @workflow_execution.state = 'completed'

      @workflow_execution.save

      PipelineMailer.complete_email(@workflow_execution).deliver_later if @workflow_execution.email_notification

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

        # This assumes the sample puid matches, i.e. happy path
        samples_workflow_execution = get_samples_workflow_executions_by_sample_puid(
          puid: sample_file_paths_tuple[:sample_puid]
        )

        @attachable_blobs_tuple_list.append({ attachable: samples_workflow_execution,
                                              blob_id_list: sample_file_blob_list })
      end
    end

    def get_samples_workflow_executions_by_sample_puid(puid:)
      @workflow_execution.samples_workflow_executions.joins(:sample).find_by(sample: { puid: })
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
        # This assumes the sample puid matches, i.e. happy path
        samples_workflow_execution = get_samples_workflow_executions_by_sample_puid(puid: sample_puid)
        samples_workflow_execution.metadata = flatten(sample_metadata)
        samples_workflow_execution.save!
      end
    end

    def merge_metadata_onto_samples
      @workflow_execution.samples_workflow_executions&.each do |swe|
        next if swe.metadata.nil?

        params = {
          'metadata' => swe.metadata,
          'analysis_id' => @workflow_execution.id
        }
        Samples::Metadata::UpdateService.new(
          swe.sample.project, swe.sample, current_user, params
        ).execute
      end
    end

    def put_output_attachments_onto_samples
      @workflow_execution.samples_workflow_executions&.each do |swe|
        next if swe.outputs.empty?

        files = swe.outputs.map { |output| output.file.signed_id }
        params = { files: }
        Attachments::CreateService.new(
          current_user, swe.sample, params
        ).execute
      end
    end
  end
end
