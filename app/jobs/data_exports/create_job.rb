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

      data_export.expires_at = set_expiry
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

    def create_sample_zip(data_export) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new_zip_file = Tempfile.new
      Zip::File.open(new_zip_file.path, create: true) do |zipfile|
        data_export.export_parameters['ids'].each do |sample_id|
          sample = Sample.find(sample_id)
          project = Project.find(sample.project_id)

          update_sample_manifest(sample, project)
          sample.attachments.each do |attachment|
            if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'
              next
            end

            current_directory = "#{project.puid}/#{sample.puid}/#{attachment.puid}"

            zipfile.add(current_directory, ActiveStorage::Blob.service.path_for(attachment.file.key))
            next unless attachment.metadata.key?('associated_attachment_id')

            zipfile.add(current_directory,
                        ActiveStorage::Blob.service.path_for(attachment.associated_attachment.file.key))
          end
        end
        zipfile.get_output_stream('manifest.json') { |f| f.write JSON.pretty_generate(JSON.parse(@manifest.to_json)) }
      end
      new_zip_file
    end

    def update_sample_manifest(sample, project) # rubocop:disable Metrics
      unless @manifest['children'].any? { |h| h['name'] == project.puid }
        @manifest['children'] << { 'name' => project.puid, 'type' => 'folder', 'irida-next-type' => 'project',
                                   'irida-next-name' => project.namespace.name, 'children' => [] }
      end

      project_directory = @manifest['children'].select { |proj| proj['name'] == project.puid }

      sample_directory = { 'name' => sample.puid,
                           'type' => 'folder',
                           'irida-next-type' => 'sample',
                           'irida-next-name' => sample.name,
                           'children' => create_attachment_manifest_directories(sample) }

      project_directory[0]['children'] << sample_directory
    end

    def create_attachment_manifest_directories(sample)
      attachment_directories = []
      sample.attachments.each do |attachment|
        next if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'

        attachment_directory = { 'name' => attachment.puid,
                                 'type' => 'folder',
                                 'irida-next-type' => 'attachment',
                                 'children' => [] }

        attachment_directory['children'] << create_attachment_file_manifest(attachment)
        if attachment.metadata.key?('associated_attachment_id')
          attachment_directory['children'] << create_attachment_file_manifest(attachment.associated_attachment)
        end

        attachment_directories << attachment_directory
      end
      attachment_directories
    end

    def create_attachment_file_manifest(attachment)
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

    def attach_zip(data_export, zip)
      data_export.file.attach(io: zip.open, filename: "#{data_export.id}.zip")
      zip.close
      zip.unlink
    end

    def set_expiry
      today = Date.current
      if today.monday? || today.tuesday?
        # Monday export will expire Thurs 12 AM
        today + 4.days
      else
        today + 6.days
      end
    end
  end
end
