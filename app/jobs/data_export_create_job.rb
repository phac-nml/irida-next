# frozen_string_literal: true

# Queues the data export create job
class DataExportCreateJob < ApplicationJob
  queue_as :default

  def perform(data_export) # rubocop:disable Metrics
    @manifest = ''
    initialize_manifest(data_export.export_type)

    new_zip = Tempfile.new
    Zip::File.open(new_zip.path, create: true) do |zipfile|
      data_export.export_parameters['ids'].each do |sample_id|
        sample = Sample.find(sample_id)
        project = Project.find(sample.project_id)

        update_manifest(sample, project)
        sample.attachments.each do |attachment|
          next if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'

          current_directory = "#{project.puid}/#{sample.puid}/#{attachment.id}/#{attachment.file.filename}"

          zipfile.add(current_directory, ActiveStorage::Blob.service.path_for(attachment.file.key))
          next unless attachment.metadata.key?('associated_attachment_id')

          paired_attachment = Attachment.find(attachment.metadata['associated_attachment_id'])
          current_directory = "#{project.puid}/#{sample.puid}/#{attachment.id}/#{paired_attachment.file.filename}"

          zipfile.add(current_directory, ActiveStorage::Blob.service.path_for(paired_attachment.file.key))
        end
      end
      puts @manifest
      zipfile.get_output_stream('manifest.json') { |f| f.write @manifest.to_json }
    end
    # @manifest.replace('=>', ': ')
    # puts @manifest
    # uid = UUIDv6::Sequence.new.call
    # We have to use string concatenation as the file pathing does not work with string interpolation
    # filename = uid + '.zip'

    # data_export = DataExport.new(export_name: 'test', export_id: uid, export_type: 'sample', status: 'processing',
    #                              export_parameters: { sample_ids: [1421, 1422, 1423] })

    # data_export.file.attach(io: new_zip.open, filename:)
    # data_export.save
    # new_zip.close
    # new_zip.unlink
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

    project_hash = @manifest['children'].select { |proj| proj['name'] == project.puid }

    sample_hash = { 'name' => sample.puid, 'type' => 'folder', 'irida-next-type' => 'sample',
                    'irida-next-name' => sample.name, 'children' => [] }

    sample.attachments.each do |attachment|
      next if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'

      attachment_folder_hash = { 'name' => attachment.id, 'type' => 'folder', 'irida-next-type' => 'attachment',
                                 'children' => [] }

      if attachment.metadata.key?('associated_attachment_id')

        attachment_hash = { 'name' => attachment.file.filename, 'type' => 'file',
                            'metadata' => { 'type' => attachment.metadata['type'], 'format' => attachment.metadata['format'], 'direction' => attachment.metadata['direction'] } }
        paired_attachment = Attachment.find(attachment.metadata['associated_attachment_id'])
        paired_attachment_hash = { 'name' => paired_attachment.file.filename, 'type' => 'file',
                                   'metadata' => { 'type' => paired_attachment.metadata['type'], 'format' => paired_attachment.metadata['format'], 'direction' => paired_attachment.metadata['direction'] } }

        attachment_folder_hash['children'] << attachment_hash
        attachment_folder_hash['children'] << paired_attachment_hash

      else
        attachment_hash = { 'name' => attachment.file.filename, 'type' => 'file',
                            'metadata' => { 'format' => attachment.metadata['format'] } }
        attachment_hash['metadata']['type'] = attachment.metadata['type'] if attachment.metadata.key?('type')
        attachment_folder_hash['children'] << attachment_hash

      end
      sample_hash['children'] << attachment_folder_hash
    end
    project_hash[0]['children'] << sample_hash
  end
end
