# frozen_string_literal: true

require 'csv'
require 'tempfile'

module WorkflowExecutions
  # Service used to Prepare a WorkflowExecution
  class PreparationService < BaseService
    include BlobHelper

    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @samplesheet_headers = parse_samplesheet_headers
      @samplesheet_rows = []
      @storage_service = ActiveStorage::Blob.service
    rescue NoMethodError => e
      @workflow_execution.errors.add(:base, "#{e.message}: workflow execution not found in executable pipelines")
      @workflow_execution.state = :error
      @workflow_execution.cleaned = true
      @workflow_execution.save
    end

    def execute # rubocop:disable Metrics/MethodLength
      # confirm params/permissions
      # build workflow execution run directory
      @workflow_execution.blob_run_directory = generate_run_directory

      # process each sample
      process_samples_workflow_executions

      # persist samplesheet in run dir
      samplesheet_key = generate_input_key(
        run_dir: @workflow_execution.blob_run_directory,
        filename: 'samplesheet.csv',
        prefix: ''
      )
      @workflow_execution.inputs.attach(io: samplesheet_file, key: samplesheet_key,
                                        filename: 'samplesheet.csv')

      @workflow_execution.workflow_params = @workflow_execution.workflow_params.merge(
        {
          input: blob_key_to_service_path(samplesheet_key),
          outdir: blob_key_to_service_path(generate_input_key(
                                             run_dir: @workflow_execution.blob_run_directory,
                                             filename: 'output',
                                             prefix: ''
                                           ), directory: true)
        }
      )

      # mark workflow execution as prepared
      @workflow_execution.state = :prepared

      @workflow_execution.save
    end

    private

    def parse_samplesheet_headers
      workflow = Irida::Pipelines.instance.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                            @workflow_execution.metadata['workflow_version'])
      workflow.samplesheet_headers
    end

    def parse_attachments_from_samplesheet(samplesheet)
      attachments = {}
      # loop through samplesheet_params to fetch attachments
      # probably stored as `gid://irida/Attachment/1234`
      samplesheet.each do |key, value|
        gid = GlobalID.parse(value)
        next unless gid && gid.model_class == Attachment

        attachments[key] = GlobalID.find(gid)
      end
      attachments
    end

    def process_samples_workflow_executions
      @workflow_execution.samples_workflow_executions.each do |sample_workflow_execution|
        attachments = parse_attachments_from_samplesheet(sample_workflow_execution.samplesheet_params)
        samplesheet_params = sample_workflow_execution.samplesheet_params

        attachments.each do |key, attachment|
          samplesheet_params[key] = copy_attachment_to_run_dir(attachment, sample_workflow_execution)
        end

        @samplesheet_rows << @samplesheet_headers.map { |header| samplesheet_params[header] }
      end
    end

    def copy_attachment_to_run_dir(attachment, attachable)
      key = generate_input_key(
        run_dir: @workflow_execution.blob_run_directory,
        filename: attachment.filename,
        prefix: format('input/%<attachable_type>s_%<attachable_id>s/',
                       attachable_type: attachment.attachable_type,
                       attachable_id: attachment.attachable_id)
      )

      blob = compose_blob_with_custom_key(attachment.file, key)

      attachable.inputs.attach(blob.signed_id)

      blob_key_to_service_path(blob.key)
    end

    def blob_key_to_service_path(blob_key, directory: false)
      path = case @storage_service.class.to_s
             when 'ActiveStorage::Service::AzureStorageService'
               format('az://%<container>s/%<key>s', container: @storage_service.container, key: blob_key)
             when 'ActiveStorage::Service::S3Service'
               format('s3://%<bucket>s/%<key>s', bucket: @storage_service.bucket, key: blob_key)
             when 'ActiveStorage::Service::GCSService'
               format('gcs://%<bucket>s/%<key>s', bucket: @storage_service.bucket, key: blob_key)
             else
               ActiveStorage::Blob.service.path_for(blob_key)
             end

      path = "#{path}/" if directory

      path
    end

    def samplesheet_file
      Tempfile.new(['samplesheet', '.csv']).tap do |file|
        CSV.open(file, 'wb') do |csv|
          csv << @samplesheet_headers

          @samplesheet_rows.each do |samplesheet_row|
            csv << samplesheet_row
          end
        end
      end
    end
  end
end
