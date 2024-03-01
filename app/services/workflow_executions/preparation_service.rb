# frozen_string_literal: true

require 'csv'
require 'tempfile'

module WorkflowExecutions
  # Service used to Prepare a WorkflowExecution
  class PreparationService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @samplesheet_headers = samplesheet_headers
      @samplesheet_rows = []
      @storage_service = ActiveStorage::Blob.service
    end

    def execute
      # confirm params/permissions
      # build workflow execution run directory
      generate_run_dir

      # process each sample
      process_samples_workflow_executions

      # persist samplesheet in run dir
      samplesheet_key = generate_input_key('samplesheet.csv')
      @workflow_execution.inputs.attach(io: samplesheet_file, key: samplesheet_key,
                                        filename: 'samplesheet.csv')

      @workflow_execution.workflow_params = @workflow_execution.workflow_params.merge(
        {
          '--input': blob_key_to_service_path(samplesheet_key),
          '--outdir': blob_key_to_service_path(generate_input_key('output'), directory: true)
        }
      )

      # mark workflow execution as prepared
      @workflow_execution.state = 'prepared'

      @workflow_execution.save
    end

    private

    def generate_run_dir
      @run_dir = ActiveStorage::Blob.generate_unique_secure_token
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

        @samplesheet_rows << samplesheet_params
      end
    end

    def generate_input_key(filename, prefix = '')
      format('%<run_dir>s/%<prefix>s%<filename>s', run_dir: @run_dir, filename:, prefix:)
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

    def copy_attachment_to_run_dir(attachment, attachable)
      key = generate_input_key(attachment.filename, format('input/%<attachable_type>s_%<attachable_id>s/',
                                                           attachable_type: attachment.attachable_type,
                                                           attachable_id: attachment.attachable_id))

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
            csv << samplesheet_row.values
          end
        end
      end
    end

    def samplesheet_headers
      workflow = Irida::Pipelines.find_pipeline_by(@workflow_execution.metadata['workflow_name'],
                                                   @workflow_execution.metadata['workflow_version'])
      sample_sheet = JSON.parse(workflow.schema_input_loc.read)
      sample_sheet['items']['properties'].keys
    end
  end
end
