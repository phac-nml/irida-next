# frozen_string_literal: true

require 'csv'
require 'tempfile'

module WorkflowExecutions
  # Service used to Prepare a WorkflowExecution
  class SamplesheetPreparationService < BaseService
    include BlobHelper

    def initialize(workflow_execution)
      super(workflow_execution.submitter, {})
      @workflow_execution = workflow_execution
      @samplesheet_headers = @workflow_execution.workflow.samplesheet_headers
      @samplesheet_rows = []
    end

    def execute_copy_step(step2d) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
      start_x = step2d.cursor[0] # x axis (outer loop)

      # iterate over sample_workflow_executions using cursor x axis to index starting point
      @workflow_execution.samples_workflow_executions.find_each.with_index do |sample_workflow_execution, index_x|
        next if index_x < start_x

        start_y = step2d.cursor[1] # y axis (inner loop)

        attachment_list = map_attachment_list(sample_workflow_execution)

        # iterate over attachments using cursor y axis to index starting point
        attachment_list.sort_by(&:id)&.[](start_y..)&.each&.with_index(start_y) do |attachment, index_y| # rubocop:disable Style/SafeNavigationChainLength
          compose_and_attach(attachment, sample_workflow_execution)

          step2d.set! [index_x, index_y + 1] # increment inner loop
        end

        step2d.set! [index_x + 1, 0] # increment outer loop
      end
    end

    def execute_processing_step # rubocop:disable Metrics/MethodLength
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

      @workflow_execution.save
    end

    private

    def map_attachment_list(sample_workflow_execution)
      parse_attachments_from_samplesheet(sample_workflow_execution.samplesheet_params).map do |_key, value|
        value
      end
    end

    def compose_and_attach(attachment, attachable)
      key = generate_attachment_key(attachment)
      blob = compose_blob_with_custom_key(attachment.file, key)

      attachable.inputs.attach(blob.signed_id)
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
      # This function could theoretically generate a lot of garbage blobs if it fails midway through.
      # We could use a 2D cursor array, but after each step a database write is needed to update the samplesheet_rows.
      # Even if the job fails so a restart occurs and extra blobs are generated, they will be cleaned up by the cleanup
      # job and as such are temporary bloat that is unlikely to create more blobs than an single extra workflow
      # execution being run simultaneously.
      @workflow_execution.samples_workflow_executions.each do |sample_workflow_execution|
        attachments = parse_attachments_from_samplesheet(sample_workflow_execution.samplesheet_params)
        samplesheet_params = sample_workflow_execution.samplesheet_params.clone

        attachments.each do |key, attachment|
          samplesheet_params[key] = generate_blob_key(attachment)
        end

        @samplesheet_rows << @samplesheet_headers.map { |header| samplesheet_params[header] }
      end
    end

    def generate_blob_key(attachment)
      blob_key_to_service_path(generate_attachment_key(attachment))
    end

    def generate_attachment_key(attachment)
      generate_input_key(
        run_dir: @workflow_execution.blob_run_directory,
        filename: attachment.filename,
        prefix: format('input/%<attachable_type>s_%<attachable_id>s/',
                       attachable_type: attachment.attachable_type,
                       attachable_id: attachment.attachable_id)
      )
    end

    def samplesheet_file
      Tempfile.create(['samplesheet', '.csv']).tap do |file|
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
