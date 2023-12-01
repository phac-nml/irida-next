# frozen_string_literal: true

require 'csv'
require 'tempfile'

module WorkflowExecutions
  # Service used to Prepare a WorkflowExecution
  class PreparationService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
      @samplesheet_headers = %w[sample fastq_1 fastq_2]
      @samplesheet_rows = []
    end

    def execute # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # confirm params/permissions
      # build workflow execution run directory
      generate_run_dir

      # does it make sense to rename the SamplesWorkflowExecution model to something better
      # e.g. SampleWorkflowExecutionParams
      @workflow_execution.samples_workflow_executions.each do |sample_workflow_execution|
        attachments = parse_attachments_from_samplesheet(sample_workflow_execution.samplesheet_params)
        samplesheet_params = sample_workflow_execution.samplesheet_params

        attachments.each do |key, attachment|
          samplesheet_params[key] = copy_attachment_to_run_dir(attachment, sample_workflow_execution)
        end

        @samplesheet_rows << samplesheet_params
      end

      # persist samplesheet in run dir
      @workflow_execution.inputs.attach(io: samplesheet_file, key: generate_input_key('samplesheet.csv'),
                                        filename: 'samplesheet.csv')

      @workflow_execution.workflow_params = @workflow_execution.workflow_params.merge(
        {
          '--input': generate_input_key('samplesheet.csv'),
          '--outdir': generate_input_key('output')
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

    def generate_input_key(filename, prefix = '')
      format('%<run_dir>s/%<prefix>s%<filename>s', run_dir: @run_dir, filename:, prefix:)
    end

    def copy_attachment_to_run_dir(attachment, attachable) # rubocop:disable Metrics/AbcSize
      key = generate_input_key(attachment.filename, format('input/%<attachable_type>s_%<attachable_id>s/',
                                                           attachable_type: attachment.attachable_type,
                                                           attachable_id: attachment.attachable_id))

      blob = ActiveStorage::Blob.new(
        key:,
        filename: attachment.filename,
        byte_size: attachment.file.byte_size,
        checksum: attachment.file.checksum,
        content_type: attachment.file.content_type
      ).tap do |copied_blob|
        copied_blob.compose([attachment.file.key])
        copied_blob.save!
      end

      attachable.inputs.attach(blob.signed_id)

      blob_to_service_path(blob)
    end

    def blob_to_service_path(blob)
      case blob.service.class.to_s
      when 'ActiveStorage::Service::AzureStorageService'
        format('az://%<container>s/%<key>s', container: blob.service.container, key: blob.key)
      when 'ActiveStorage::Service::S3Service'
        format('s3://%<bucket>s/%<key>s', bucket: blob.service.bucket, key: blob.key)
      when 'ActiveStorage::Service::GCSService'
        format('gcs://%<bucket>s/%<key>s', bucket: blob.service.bucket, key: blob.key)
      else
        ActiveStorage::Blob.service.path_for(blob.key)
      end
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
  end
end
