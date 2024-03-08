# frozen_string_literal: true

# Queues the data export create job
class DataExportCreateJob < ApplicationJob
  queue_as :default

  def perform(data_export)
    @manifest = ''

    initialize_manifest(data_export.export_type)

    zip = create_zip(data_export)

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

  def update_manifest(sample, project) # rubocop:disable Metrics
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

      attachment_directory = { 'name' => attachment.id, 'type' => 'folder', 'irida-next-type' => 'attachment',
                               'children' => [] }
      if attachment.metadata.key?('associated_attachment_id')
        attachment_directory['children'] << create_attachment_file_manifest(attachment.associated_attachment)
      end
      attachment_directory['children'] << create_attachment_file_manifest(attachment)

      attachment_directories << attachment_directory
    end
    attachment_directories
  end

  def create_attachment_file_manifest(attachment)
    attachment_manifest_file = { 'name' => attachment.file.filename,
                                 'type' => 'file',
                                 'metadata' => { 'format' => attachment.metadata['format'] } }
    if attachment.metadata.key?('direction')
      attachment_manifest_file['metadata']['direction'] = attachment.metadata['direction']
    end
    attachment_manifest_file['metadata']['type'] = attachment.metadata['type'] if attachment.metadata.key?('type')
    attachment_manifest_file
  end

  def create_zip(data_export) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    zip_file = Tempfile.new
    Zip::File.open(zip_file.path, create: true) do |zipfile|
      data_export.export_parameters['ids'].each do |sample_id|
        sample = Sample.find(sample_id)
        project = Project.find(sample.project_id)

        update_manifest(sample, project)
        sample.attachments.each do |attachment|
          next if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'

          current_directory = "#{project.puid}/#{sample.puid}/#{attachment.id}/#{attachment.file.filename}"

          zipfile.add(current_directory, ActiveStorage::Blob.service.path_for(attachment.file.key))
          next unless attachment.metadata.key?('associated_attachment_id')

          paired_attachment = attachment.associated_attachment
          current_directory = "#{project.puid}/#{sample.puid}/#{attachment.id}/#{paired_attachment.file.filename}"

          zipfile.add(current_directory, ActiveStorage::Blob.service.path_for(paired_attachment.file.key))
        end
      end
      zipfile.get_output_stream('manifest.json') { |f| f.write JSON.pretty_generate(JSON.parse(@manifest.to_json)) }
    end
    zip_file
  end

  def attach_zip(data_export, zip)
    data_export.file.attach(io: zip.open, filename: "#{data_export.id}.zip")
    zip.close
    zip.unlink
  end

  def set_expiry
    today = Date.current
    if today.monday? || today.tuesday?
      today + 3.days
    else
      today + 5.days
    end
  end
end
