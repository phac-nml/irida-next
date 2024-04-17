# frozen_string_literal: true

module DataExports
  # Queues the data export create job
  class CreateJob < ApplicationJob # rubocop:disable Metrics/ClassLength
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

    # Functions used by both sample and analysis exports-------------------------------------------------
    def initialize_manifest(export_type)
      @manifest = if export_type == 'sample'
                    { 'type' => 'Samples Export', 'date' => Date.current, 'children' => [] }
                  else
                    { 'type' => 'Analysis Export', 'date' => Date.current, 'children' => [] }
                  end
    end

    def write_attachment(directory, zip, attachment)
      zip.write_file(directory) do |writer_for_file|
        attachment.file.download { |chunk| writer_for_file << chunk }
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

    # Sample export specific functions------------------------------------------------------------------
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
        directory = "#{project.puid}/#{sample.puid}/#{attachment.puid}/#{attachment.file.filename}"
        write_attachment(directory, zip, attachment)
      end
    end

    # Analysis export specific functions---------------------------------------------------------------------
    def create_analysis_zip(data_export)
      new_zip_file = Tempfile.new(binmode: true)
      ZipKit::Streamer.open(new_zip_file) do |zip|
        workflow_execution = WorkflowExecution.includes(
          outputs: { file_attachment: :blob }, samples_workflow_executions: [:sample,
                                                                             { outputs: { file_attachment: :blob } }]
        ).find(data_export.export_parameters['ids'][0])

        write_workflow_execution_outputs_and_manifest(workflow_execution, zip)

        samples_workflow_executions = workflow_execution.samples_workflow_executions
        samples_workflow_executions.each do |swe|
          write_samples_workflow_execution_outputs_and_manifest(swe, zip) unless swe.outputs.empty?
        end
        # Write manifest to file 'manifest.json' and add to zip
        write_manifest(zip)
      end
      new_zip_file
    end

    def write_workflow_execution_outputs_and_manifest(workflow_execution, zip)
      workflow_execution.outputs.each do |output|
        write_attachment(output.file.filename.to_s, zip, output)

        @manifest['children'] << { 'name' => output.file.filename.to_s, 'type' => 'file' }
      end
    end

    def write_samples_workflow_execution_outputs_and_manifest(swe, zip)
      sample = swe.sample
      sample_directory = { 'name' => sample.puid, 'type' => 'folder', 'irida-next-type' => 'sample',
                           'irida-next-name' => sample.name, 'children' => [] }
      swe.outputs.each do |output|
        directory = "#{sample.puid}/#{output.file.filename}"
        write_attachment(directory, zip, output)

        sample_directory['children'] << { 'name' => output.file.filename.to_s, 'type' => 'file' }
      end

      @manifest['children'] << sample_directory
    end
  end
end
