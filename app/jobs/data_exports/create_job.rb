# frozen_string_literal: true

module DataExports
  # Queues the data export create job
  class CreateJob < ApplicationJob
    queue_as :default

    def perform(data_export)
      @manifest = ''
      initialize_manifest(data_export.export_type)

      zip = create_sample_zip(data_export) if data_export.export_type == 'sample'

      attach_zip(data_export, zip)

      data_export.manifest = @manifest.to_json
      data_export.expires_at = ApplicationController.helpers.add_business_days(DateTime.current, 3)
      data_export.status = 'ready'
      data_export.save
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
        samples = Sample.includes(attachments: { file_attachment: :blob })
                        .where(id: data_export.export_parameters['ids'])
        samples.each do |sample|
          next unless sample.attachments.count.positive?

          project = sample.project

          update_sample_manifest(sample, project)

          write_attachments(sample, project, zip)
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
      attachment_directories = []
      sample.attachments.each do |attachment|
        next if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'

        attachment_directory = { 'name' => attachment.puid,
                                 'type' => 'folder',
                                 'irida-next-type' => 'attachment',
                                 'children' => [] }

        attachment_directory['children'] << create_attachment_manifest_file(attachment)
        if attachment.metadata.key?('associated_attachment_id')
          attachment_directory['children'] << create_attachment_manifest_file(attachment.associated_attachment)
        end

        attachment_directories << attachment_directory
      end
      attachment_directories
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

    def write_attachments(sample, project, zip)
      sample.attachments.each do |attachment|
        write_attachment(project.puid, sample.puid, zip, attachment)
      end
    end

    def write_attachment(project_puid, sample_puid, zip, attachment)
      directory = "#{project_puid}/#{sample_puid}/#{attachment.puid}/#{attachment.file.filename}"
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
  end
end
