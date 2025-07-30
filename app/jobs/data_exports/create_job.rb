# frozen_string_literal: true

module DataExports
  # Queues the data export create job
  class CreateJob < ApplicationJob # rubocop:disable Metrics/ClassLength
    queue_as :default
    queue_with_priority do
      data_export = arguments.first
      case data_export.export_type
      when 'sample', 'analysis'
        40
      when 'linelist'
        35
      end
    end

    def perform(data_export)
      initialize_manifest(data_export.export_type) unless data_export.export_type == 'linelist'

      Tempfile.create(binmode: true) do |temp_export_file|
        create_export(data_export, temp_export_file)
        temp_export_file.rewind
        attach_export(data_export, temp_export_file)
      end

      assign_data_export_attributes(data_export)

      DataExportMailer.export_ready(data_export).deliver_later if data_export.email_notification?
    end

    # Functions used by all exports (sample, analysis, linelist)-------------------------------------------------
    def create_export(data_export, temp_export_file)
      case data_export.export_type
      when 'sample'
        create_sample_zip(data_export, temp_export_file)
      when 'analysis'
        create_analysis_zip(data_export, temp_export_file)
      when 'linelist'
        create_linelist_spreadsheet(data_export, temp_export_file)
      end
    end

    def attach_export(data_export, export)
      filename = if data_export.export_type == 'linelist'
                   "#{data_export.id}.#{data_export.export_parameters['linelist_format']}"
                 else
                   "#{data_export.id}.zip"
                 end

      data_export.file.attach(io: export, filename:)
    end

    def assign_data_export_attributes(data_export)
      data_export.manifest = @manifest.to_json unless data_export.export_type == 'linelist'
      data_export.expires_at = ApplicationController.helpers.add_business_days(DateTime.current, 3)
      data_export.status = 'ready'
      data_export.save
    end

    # Functions used by both sample and analysis exports-------------------------------------------------
    def initialize_manifest(export_type)
      @manifest = if export_type == 'sample'
                    { 'type' => 'Samples Export', 'date' => Date.current, 'children' => [] }
                  elsif export_type == 'analysis'
                    { 'type' => 'Analysis Export', 'date' => Date.current, 'children' => [] }
                  end
    end

    def write_attachment(directory, zip, attachment)
      zip.write_file(directory) do |writer_for_file|
        attachment.file.download { |chunk| writer_for_file << chunk }
      end
    end

    def write_manifests(zip, data_export_id)
      # Full manifest
      zip.write_file('manifest.json') do |manifest_zip_file|
        manifest_zip_file.write(JSON.pretty_generate(JSON.parse(@manifest.to_json)))
      end
      # Simple manifest
      zip.write_file('manifest.txt') do |manifest_zip_file|
        manifest_zip_file.write(generate_simple_manifest(data_export_id))
      end
    end

    def generate_simple_manifest(data_export_id)
      output_lines = [
        @manifest['type'],
        @manifest['date'],
        '',
        'contents:',
        "#{data_export_id}/"
      ]

      child_count = @manifest['children'].count
      @manifest['children'].each_with_index do |child, index|
        # push with * is used to flatten array without creating a new array
        output_lines.push(*simple_manifest_gen_lines_recursive(
          cursor: child, prefix: '', final_child: child_count == index + 1
        ))
      end

      output_lines.join("\n")
    end

    def simple_manifest_gen_lines_recursive(cursor:, prefix: '', final_child: false) # rubocop:disable Metrics/MethodLength
      output = []

      # when the current cursor is the final child of the parent, we change which symbols are used to generate the lines
      if final_child
        line = "#{prefix}└─ #{cursor['name']}"
        child_prefix = "#{prefix}   "
      else
        line = "#{prefix}├─ #{cursor['name']}"
        child_prefix = "#{prefix}│  "
      end

      line += '/' if cursor['type'] == 'folder'
      line += " (#{cursor['irida-next-name']})" if cursor.key?('irida-next-name')
      output.append(line)

      if cursor['type'] == 'folder'
        child_count = cursor['children'].count
        cursor['children'].each_with_index do |child, index|
          # push with * is used to flatten array without creating a new array
          output.push(*simple_manifest_gen_lines_recursive(
            cursor: child, prefix: child_prefix, final_child: child_count == index + 1
          ))
        end
      end

      output # array of lines
    end

    # Sample export specific functions------------------------------------------------------------------
    def create_sample_zip(data_export, temp_export_file)
      temp_export_file.tap do |tempfile|
        ZipKit::Streamer.open(tempfile) do |zip|
          samples = sample_query(data_export.export_parameters['ids'])
          samples.each do |sample|
            next if sample.attachments.empty?

            attachments = attachments_query(sample, data_export)

            next if attachments.empty?

            project = sample.project

            update_sample_manifest(sample, project, attachments)

            write_sample_attachments(sample, project, zip, attachments)
          end
          write_manifests(zip, data_export.id)
        end
      end
    end

    def update_sample_manifest(sample, project, attachments)
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
                           'children' => create_attachment_manifest_directories(attachments) }

      project_directory['children'] << sample_directory
    end

    def create_attachment_manifest_directories(attachments)
      attachment_directories = {}
      attachments.each do |attachment|
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

    def write_sample_attachments(sample, project, zip, attachments)
      attachments.each do |attachment|
        directory = "#{project.puid}/#{sample.puid}/#{attachment.puid}/#{attachment.file.filename}"
        write_attachment(directory, zip, attachment)
      end
    end

    # Analysis export specific functions---------------------------------------------------------------------
    def create_analysis_zip(data_export, temp_export_file)
      temp_export_file.tap do |tempfile|
        ZipKit::Streamer.open(tempfile) do |zip|
          workflow_executions = workflow_query(data_export.export_parameters['ids'])
          workflow_executions.each do |workflow|
            next if workflow.outputs.empty?

            write_workflow_execution_outputs_and_manifest(workflow, zip)

            workflow.samples_workflow_executions.each do |swe|
              write_samples_workflow_execution_outputs_and_manifest(workflow.id, swe, zip) unless swe.outputs.empty?
            end
          end
          write_manifests(zip, data_export.id)
        end
      end
    end

    def write_workflow_execution_outputs_and_manifest(workflow_execution, zip)
      workflow_execution_directory =
        { 'name' => workflow_execution.id,
          'type' => 'folder',
          'irida-next-type' => 'workflow_execution',
          'irida-next-name' => workflow_execution.name.nil? ? workflow_execution.id : workflow_execution.name,
          'children' => [] }

      workflow_execution.outputs.each do |output|
        directory = "#{workflow_execution.id}/#{output.file.filename}"
        write_attachment(directory, zip, output)
        workflow_execution_directory['children'] << { 'name' => output.file.filename.to_s, 'type' => 'file' }
      end
      @manifest['children'] << workflow_execution_directory
    end

    def write_samples_workflow_execution_outputs_and_manifest(we_id, swe, zip)
      sample_params = retrieve_swe_sample_params(swe)
      sample_directory = { 'name' => sample_params['puid'], 'type' => 'folder', 'irida-next-type' => 'sample',
                           'irida-next-name' => sample_params['name'], 'children' => [] }
      swe.outputs.each do |output|
        directory = "#{we_id}/#{sample_params['puid']}/#{output.file.filename}"
        write_attachment(directory, zip, output)

        sample_directory['children'] << { 'name' => output.file.filename.to_s, 'type' => 'file' }
      end
      @manifest['children'].detect { |we| we['name'] == we_id }['children'] << sample_directory
    end

    def retrieve_swe_sample_params(swe)
      sample_params = { 'puid' => swe.samplesheet_params['sample'] }
      sample = swe.sample

      # Handles if sample has been previously deleted
      if sample.nil?
        sample_params['name'] =
          swe.samplesheet_params.key?('sample_name') ? swe.samplesheet_params['sample_name'] : 'Deleted Sample'
      else
        sample_params['name'] = sample.name
      end
      sample_params
    end

    # Linelist export specific functions---------------------------------------------------------------------
    def create_linelist_spreadsheet(data_export, temp_export_file)
      samples = Sample.includes(project: :namespace).where(id: data_export.export_parameters['ids'])
      if data_export.export_parameters['linelist_format'] == 'csv'
        write_csv_export(data_export, samples, temp_export_file)
      else
        write_xlsx_export(data_export, samples, temp_export_file)
      end
    end

    def write_csv_export(data_export, samples, temp_export_file)
      temp_export_file.tap do |tempfile|
        CSV.open(tempfile, 'wb') do |csv|
          csv << write_spreadsheet_header(data_export.export_parameters['metadata_fields'])
          samples.each do |sample|
            csv << write_spreadsheet_row(sample, data_export)
          end
        end
      end
    end

    def write_xlsx_export(data_export, samples, temp_export_file)
      temp_export_file.tap do |tempfile|
        Axlsx::Package.new do |workbook|
          workbook.workbook.add_worksheet(name: 'linelist') do |sheet|
            sheet.add_row write_spreadsheet_header(data_export.export_parameters['metadata_fields'])
            samples.each do |sample|
              sheet.add_row write_spreadsheet_row(sample, data_export)
            end
          end
          workbook.serialize(tempfile.path)
        end
      end
    end

    def write_spreadsheet_header(metadata_fields)
      header = ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID']
      header += metadata_fields.map(&:upcase)
      header
    end

    def write_spreadsheet_row(sample, data_export)
      row = [sample.puid, sample.name, sample.project.puid]
      row += map_metadata_fields(data_export.export_parameters['metadata_fields'], sample.metadata)
      row
    end

    def map_metadata_fields(metadata_fields, sample_metadata)
      metadata_fields.map do |metadata_field|
        if sample_metadata.key?(metadata_field)
          sample_metadata[metadata_field]
        else
          ''
        end
      end
    end

    # Queries---------------------------------------------------------------------
    def sample_query(sample_ids)
      Sample.includes(project: :namespace, attachments: { file_attachment: :blob })
            .where(id: sample_ids)
    end

    def attachments_query(sample, data_export)
      if (Attachment::FORMAT_REGEX.keys - data_export.export_parameters['attachment_formats']).empty?
        sample.attachments
      else
        sample.attachments.select do |attachment|
          data_export.export_parameters['attachment_formats'].include?(attachment.metadata['format'])
        end
      end
    end

    def workflow_query(workflow_ids)
      WorkflowExecution.includes(
        outputs: { file_attachment: :blob },
        samples_workflow_executions: [:sample, { outputs: { file_attachment: :blob } }]
      ).where(id: workflow_ids)
    end
  end
end
