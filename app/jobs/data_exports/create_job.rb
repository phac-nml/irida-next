# frozen_string_literal: true

module DataExports
  # Queues the data export create job
  class CreateJob < ApplicationJob
    queue_as :default

    def perform(data_export)
      @manifest = ''
      initialize_manifest(data_export.export_type)

      zip = data_export.export_type == 'sample' ? create_sample_zip(data_export) : create_analysis_zip(data_export)

      attach_zip(data_export, zip)

      data_export.manifest = @manifest.to_json
      data_export.expires_at = ApplicationController.helpers.add_business_days(DateTime.current, 3)
      data_export.status = 'ready'
      data_export.save

      DataExportMailer.export_ready(data_export).deliver_later if data_export.email_notification?
    end

    def initialize_manifest(export_type)
      @manifest = if export_type == 'sample'
                    { 'type' => 'Samples Export', 'date' => Date.current, 'children' => [] }
                  else
                    { 'type' => 'Analysis Export', 'date' => Date.current, 'children' => [] }
                  end
    end

    def create_sample_zip(data_export)
      new_zip_file = Tempfile.new(binmode: true)
      ZipKit::Streamer.open(new_zip_file) do |zip|
        samples = Sample.includes(project: :namespace, attachments: { file_attachment: :blob })
                        .where(id: data_export.export_parameters['ids'])
        samples.each do |sample|
          next if sample.attachments.empty?

          project = sample.project

          update_sample_manifest(sample, project)

          write_sample_attachments(sample, project, zip)
        end
        # Write manifest to file 'manifest.json' and add to zip
        write_manifest(zip)
      end
      new_zip_file
    end

    def create_analysis_zip(data_export)
      new_zip_file = Tempfile.new(binmode: true)
      ZipKit::Streamer.open(new_zip_file) do |zip|
        workflow_execution = WorkflowExecution.find(data_export.export_parameters['ids'][0])
        write_workflow_execution_outputs(workflow_execution)

        sample_workflow_executions = SamplesWorkflowExecution.where(workflow_execution_id: workflow_execution.id)
        sample_workflow_executions.each do |swe|
          write_sample_workflow_execution_outputs(swe, zip) if swe.outputs.count.positive?
        end

        update_analysis_manifest(workflow_execution, sample_workflow_executions)
        # Write manifest to file 'manifest.json' and add to zip
        write_manifest(zip)
      end
      new_zip_file
    end

    def update_sample_manifest(sample, project)
      project_directory = ''
      # Check if project directory already exists in manifest, else create it
      if @manifest['children'].any? { |h| h['name'] == project.puid }
        project_directory = @manifest['children'].detect { |proj| proj['name'] == project.puid }
      else
        project_directory = { 'name' => project.puid, 'type' => 'folder', 'irida-next-type' => 'project',
                              'irida-next-name' => project.namespace.name, 'children' => [] }
        @manifest['children'] << project_directory
      end

      sample_directory = { 'name' => sample.puid,
                           'type' => 'folder',
                           'irida-next-type' => 'sample',
                           'irida-next-name' => sample.name,
                           'children' => create_attachment_manifest_directories(sample) }

      project_directory['children'] << sample_directory
    end

    def update_analysis_manifest(workflow_execution, sample_workflow_executions)
      add_workflow_execution_outputs_to_manifest(workflow_execution)

      add_sample_workflow_executions_to_manifest(sample_workflow_executions)
    end

    def create_attachment_manifest_directories(sample)
      attachment_directories = {}
      sample.attachments.each do |attachment|
        unless attachment_directories.key?(attachment.puid)
          attachment_directories[attachment.puid] = { 'name' => attachment.puid,
                                                      'type' => 'folder',
                                                      'irida-next-type' => 'attachment',
                                                      'children' => [] }
        end
        attachment_directories[attachment.puid]['children'] << create_attachment_manifest_file(attachment)
      end
      attachment_directories.values
    end

    def create_attachment_manifest_file(attachment)
      attachment_manifest_file = { 'name' => attachment.file.filename,
                                   'type' => 'file',
                                   'metadata' => {
                                     'format' => attachment.metadata['format']
                                   } }
      if attachment.metadata.key?('direction')
        attachment_manifest_file['metadata']['direction'] = attachment.metadata['direction']
      end
      attachment_manifest_file['metadata']['type'] = attachment.metadata['type'] if attachment.metadata.key?('type')
      attachment_manifest_file
    end

    def write_sample_attachments(sample, project, zip)
      sample.attachments.each do |attachment|
        write_attachment(project.puid, sample.puid, zip, attachment)
      end
    end

    def write_attachment(directory, zip, attachment)
      zip.write_file(directory) do |writer_for_file|
        attachment.file.download { |chunk| writer_for_file << chunk }
      end
    end

    def write_workflow_execution_outputs(workflow_execution, zip)
      workflow_execution.outputs.each do |output|
        write_attachment(output.file.filename.to_s, zip, output)
      end
    end

    def write_sample_workflow_execution_outputs(swe, zip)
      sample = Sample.find(swe.sample_id)
      swe.outputs.each do |output|
        directory = "#{sample.puid}/#{output.puid}"
        write_attachment(directory, zip, output)
      end
    end

    def add_workflow_execution_outputs_to_manifest(workflow_execution)
      workflow_execution.outputs.each do |workflow_execution_output|
        @manifest['children'] << { 'name' => workflow_execution_output.file.filename.to_s, 'type' => 'file' }
      end
    end

    def add_sample_workflow_executions_to_manifest(sample_workflow_executions)
      sample_workflow_executions.each do |sample_workflow_execution|
        sample_directory = ''
        sample = Sample.find_by(sample_workflow_execution.sample_id)
        if @manifest['children'].any? { |h| h['name'] == sample.puid }
          sample_directory = @manifest['children'].detect { |s| s['name'] == sample.puid }
        else
          sample_directory = { 'name' => sample.puid, 'type' => 'folder', 'irida-next-type' => 'sample',
                               'irida-next-name' => sample.name, 'children' => [] }
          @manifest['children'] << sample_directory
        end

        add_sample_workflow_execution_output_to_manifest(sample_directory, sample_workflow_execution)
      end
    end

    def add_sample_workflow_execution_output_to_manifest(directory, sample_workflow_execution)
      sample_workflow_execution.outputs.each do |sample_workflow_execution_output|
        directory['children'] << { 'name' => sample_workflow_execution_output.file.filename.to_s,
                                   'type' => 'file' }
      end
    end

    def write_manifest(zip)
      manifest_file = Tempfile.new
      manifest_file.write(JSON.pretty_generate(JSON.parse(@manifest.to_json)))
      zip.write_file('manifest.json') { |writer_for_file| IO.copy_stream(manifest_file.open, writer_for_file) }

      manifest_file.close
      manifest_file.unlink
    end

    def attach_zip(data_export, zip)
      data_export.file.attach(io: zip.open, filename: "#{data_export.id}.zip")
      zip.close
      zip.unlink
    end
  end
end
