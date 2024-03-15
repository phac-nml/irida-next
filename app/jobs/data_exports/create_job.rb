# frozen_string_literal: true

# module DataExports
module DataExports
  # Queues the data export create job
  class CreateJob < ApplicationJob # rubocop:disable Method/ClassLength
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
      new_zip_file = Tempfile.new(binmode: true)
      ZipKit::Streamer.open(new_zip_file) do |zip|
        data_export.export_parameters['ids'].each do |sample_id|
          sample = Sample.find(sample_id)
          project = Project.find(sample.project_id)
          next unless sample.attachments.count.positive?

          update_sample_manifest(sample, project)

          sample.attachments.each do |attachment|
            if attachment.metadata.key?('associated_attachment_id') && attachment.metadata['direction'] == 'reverse'
              next
            end

            directory = "#{project.puid}/#{sample.puid}/#{attachment.puid}/#{attachment.file.filename}"
            zip.write_file(directory) do |writer_for_file|
              attachment.file.download { |chunk| writer_for_file << chunk }
            end

            next unless attachment.metadata.key?('associated_attachment_id')

            paired_attachment = attachment.associated_attachment
            directory = "#{project.puid}/#{sample.puid}/#{attachment.puid}/#{paired_attachment.file.filename}"
            zip.write_file(directory) do |writer_for_file|
              paired_attachment.file.download { |chunk| writer_for_file << chunk }
            end
          end
        end
        # Write manifest to file 'manifest.json' and add to zip
        manifest_file = Tempfile.new
        manifest_file.write(JSON.pretty_generate(JSON.parse(@manifest.to_json)))

        zip.write_file('manifest.json') { |writer_for_file| IO.copy_stream(manifest_file.open, writer_for_file) }
        manifest_file.close
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
      expiry = 3.business_days.from_now
      # Because the Holidays gem does not have great filters for specific federal holidays, we have to filter
      # with the BC, ON, and CAN holidays to get a two lists, observed and informal holidays. However the lists also
      # contain many non-Federal holidays, so we need a hard-coded list of holidays, and filter through them to check
      # for matches to add extra days to our expiry.
      observed_holidays = ["New Year's Day", 'Good Friday', 'Victoria Day', 'Canada Day', 'Labour Day',
                           'National Day for Truth and Reconciliation', 'Thanksgiving',
                           'Remembrance Day', 'Christmas Day', 'Boxing Day']
      informal_holidays = ['Easter Monday', 'Civic Holiday']

      check_formal_holidays = Holidays.between(Date.current, expiry, %i[ca_bc ca_on ca], :observed)
      check_informal_holidays = Holidays.between(Date.current, expiry, %i[ca_bc ca_on ca], :informal)

      extra_days = 0
      extra_days += add_holidays(check_formal_holidays, observed_holidays) if check_formal_holidays.count.positive?
      extra_days += add_holidays(check_informal_holidays, informal_holidays) if check_informal_holidays.count.positive?
      extra_days.business_days.after(expiry)
    end

    def add_holidays(days_to_check, holidays)
      extra_days = 0
      holidays.each do |holiday|
        if days_to_check.any? { |h| h[:name] == holiday }
          extra_days += 1
          next
        end
      end
      extra_days
    end
  end
end
