# frozen_string_literal: true

# Queues the workflow execution completion job
class WorkflowExecutionCompletionJob < WorkflowExecutionJob # rubocop:disable Metrics/ClassLength
  include ActiveJob::Continuable
  include BlobHelper
  include MetadataHelper

  queue_as :default
  queue_with_priority 10

  def perform(workflow_execution)
    @workflow_execution = workflow_execution

    unless validate_initial_state(@workflow_execution, [:completing], validate_run_id: false)
      update_state(:error, force: true)
    end

    step :process_global_file_paths
    step :process_sample_file_paths, start: 0
    step :process_samples_metadata, start: 0
    step :merge_metadata_onto_samples, start: 0
    step :put_output_attachments_onto_samples, start: 0
    step :create_activities, start: 0

    step :update_state_step
    step :queue_next_job
  end

  private

  def process_global_file_paths
    return if @workflow_execution.state.to_sym == :error

    # Handle output files for workflow execution
    blob_id_list = run_output_global_file_paths&.map do |blob_file_path|
      download_and_make_new_blob(blob_file_path:)
    end

    create_attachment(@workflow_execution, blob_id_list) unless blob_id_list.nil?
  end

  def process_sample_file_paths(step) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if @workflow_execution.state.to_sym == :error

    run_output_samples_file_paths&.[](step.cursor..)&.each do |sample_file_paths_tuple| # :sample_puid, :data_paths
      blob_id_list = sample_file_paths_tuple[:data_paths]&.map do |blob_file_path|
        download_and_make_new_blob(blob_file_path:)
      end

      samples_workflow_execution = get_samples_workflow_executions_by_sample_puid(
        puid: sample_file_paths_tuple[:sample_puid]
      )

      unless blob_id_list.nil? || samples_workflow_execution.nil?
        create_attachment(samples_workflow_execution, blob_id_list)
      end

      step.advance!
    end
  end

  def run_output_global_file_paths
    return nil unless run_output_data['files']['global']

    get_path_mapping(run_output_data['files']['global'])
  end

  def run_output_samples_file_paths
    return nil unless run_output_data['files']['samples']

    samples_paths = []
    run_output_data['files']['samples'].each do |sample_puid, sample_data_paths|
      data_paths = get_path_mapping(sample_data_paths)

      samples_paths.append({ sample_puid:, data_paths: })
    end
    samples_paths
  end

  def get_path_mapping(data_paths)
    data_paths.map { |entry| run_output_base_path + entry['path'] }
  end

  def create_attachment(attachable, blob_id_list, additional_params = {})
    params = additional_params.merge({ files: blob_id_list })
    # Since this attaches multiple attachments to the same sample, each on it's own step within the CreateService,
    # there is an edge case where the same attachment could be attached twice if the job is interrupted after the
    # first attachment is created but before the step is advanced.
    Attachments::CreateService.new(
      @workflow_execution.submitter, attachable, params
    ).execute
  end

  def run_output_base_path
    @run_output_base_path ||= "#{@workflow_execution.blob_run_directory}/output/"
  end

  def run_output_data
    @run_output_data ||= begin
      output_json_path = "#{run_output_base_path}iridanext.output.json.gz"
      download_decompress_parse_gziped_json(output_json_path)
    end
  end

  def process_samples_metadata(step) # rubocop:disable Metrics/AbcSize
    return if @workflow_execution.state.to_sym == :error
    return unless run_output_data['metadata']['samples']

    items = []
    run_output_data['metadata']['samples']&.each do |sample_puid, sample_metadata|
      items.append({ sample_puid:, sample_metadata: })
    end

    items[step.cursor..].each do |i|
      # This assumes the sample puid matches, i.e. happy path
      samples_workflow_execution = get_samples_workflow_executions_by_sample_puid(puid: i[:sample_puid])
      samples_workflow_execution.metadata = flatten(i[:sample_metadata])
      samples_workflow_execution.save!

      step.advance!
    end
  end

  def get_samples_workflow_executions_by_sample_puid(puid:)
    @workflow_execution.samples_workflow_executions.find_by(
      Arel::Nodes::InfixOperation.new(
        '->>', SamplesWorkflowExecution.arel_table[:samplesheet_params], Arel::Nodes::Quoted.new('sample')
      ).eq(puid)
    )
  end

  def samples_workflow_executions_map
    @workflow_execution.samples_workflow_executions.map do |swe|
      swe
    end
  end

  def merge_metadata_onto_samples(step) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return if @workflow_execution.state.to_sym == :error
    return unless @workflow_execution.update_samples?

    samples_workflow_executions_map[step.cursor..].each do |swe|
      unless swe.sample.nil? || swe.metadata.nil?
        params = {
          'metadata' => swe.metadata,
          'analysis_id' => @workflow_execution.id,
          include_activity: false,
          'force_update' => true
        }
        Samples::Metadata::UpdateService.new(
          swe.sample.project, swe.sample, @workflow_execution.submitter, params
        ).execute
      end

      step.advance!
    end
  end

  def put_output_attachments_onto_samples(step)
    return if @workflow_execution.state.to_sym == :error
    return unless @workflow_execution.update_samples?

    samples_workflow_executions_map[step.cursor..].each do |swe|
      next if swe.sample.nil? || swe.outputs.empty?

      files = swe.outputs.map { |output| output.file.signed_id }

      create_attachment(swe.sample, files, { include_activity: false })

      step.advance!
    end
  end

  def create_activities(step) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return if @workflow_execution.state.to_sym == :error
    return unless @workflow_execution.update_samples?
    return unless @workflow_execution.submitter.automation_bot?

    samples_workflow_executions_map[step.cursor..].each do |swe|
      next if swe.sample.nil? || (swe.metadata.nil? && swe.outputs.empty?)

      parameters = { workflow_id: @workflow_execution.id, sample_id: swe.sample.id, sample_puid: swe.sample.puid }

      if !swe.metadata.nil? && !swe.outputs.empty?
        @workflow_execution.namespace.create_activity(
          key: 'workflow_execution.automated_workflow_completion.outputs_and_metadata_written', parameters:
        )
      elsif swe.metadata.nil?
        @workflow_execution.namespace.create_activity(
          key: 'workflow_execution.automated_workflow_completion.outputs_written', parameters:
        )
      else
        @workflow_execution.namespace.create_activity(
          key: 'workflow_execution.automated_workflow_completion.metadata_written', parameters:
        )
      end

      step.advance!
    end
  end

  def update_state_step
    return if @workflow_execution.state.to_sym == :error

    update_state(:completed)
  end

  def update_state(state, force: false)
    return if @workflow_execution.state.to_sym == state

    if force
      # validation must be skipped in the case where model is already invalid (e.g. no namespace)
      @workflow_execution.update_attribute('state', :error) # rubocop:disable Rails/SkipsModelValidations
    else
      @workflow_execution.state = state
      @workflow_execution.save
    end
  end

  def queue_next_job
    WorkflowExecutionCleanupJob.perform_later(@workflow_execution.reload)
  end
end
