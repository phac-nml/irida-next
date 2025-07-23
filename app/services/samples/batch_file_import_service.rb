# frozen_string_literal: true

require 'roo'

module Samples
  # Service used to batch create samples via a file
  class BatchFileImportService < BaseSpreadsheetImportService # rubocop:disable Metrics/ClassLength
    def initialize(namespace, user = nil, blob_id = nil, params = {})
      @sample_name_column = params[:sample_name_column]
      @sample_description_column = params[:sample_description_column]
      @metadata_fields = params[:metadata_fields] if params[:metadata_fields]
      required_headers = [@sample_name_column]
      if namespace.group_namespace?
        @project_puid_column = params[:project_puid_column]
        required_headers.push @project_puid_column if params[:project_puid_column].present?
        @static_project = params[:static_project_id].blank? ? nil : Project.find(params[:static_project_id])
      else
        @static_project = namespace.project
      end
      @imported_samples_data = { project_data: {}, group_data: [] }
      @project_puid_map = {}
      super(namespace, user, blob_id, required_headers, 0, params)
    end

    def execute(broadcast_target = nil)
      begin
      authorize! @namespace, to: :import_samples_and_metadata?
      validate_file
      perform_file_import(broadcast_target)
      ensure
        cleanup_files
      end
    rescue FileImportError => e
      @namespace.errors.add(:base, e.message)
      {}
    end

    protected

    def perform_file_import(broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      response = {}
      parse_settings = @headers.zip(@headers).to_h

      # minus 1 to exclude header
      total_sample_count = @spreadsheet.count - 1
      @spreadsheet.each_with_index(parse_settings) do |data, index|
        next unless index.positive?

        update_progress_bar(index, total_sample_count, broadcast_target)

        sample_name = data[@sample_name_column]

        project_puid = data[@project_puid_column]
        description = data[@sample_description_column]
        metadata = process_metadata_row(data)

        error = errors_on_sample_row(sample_name, project_puid, response, index)
        unless error.nil?
          response["index #{index}"] = error
          next
        end

        if project_puid
          project = Namespaces::ProjectNamespace.find_by(puid: project_puid)&.project
          error = errors_with_project(project_puid, project)
          unless error.nil?
            response[sample_name] = error
            next
          end
        elsif @static_project
          project = @static_project
        else
          next
        end

        response[sample_name] = process_sample_row(sample_name, project, description, metadata)
      end
      create_activities unless @imported_samples_data[:project_data].empty?

      response
    end

    private

    def accessible_from_namespace?(project)
      if @namespace.project_namespace?
        @namespace.id == project.namespace.id
      elsif @namespace.group_namespace?
        group_namespace_projects.select { |proj| proj.id == project.id }.count.positive?
      else
        false
      end
    end

    def errors_on_sample_row(sample_name, project_puid, response, index)
      if sample_name.nil? || (project_puid.nil? && @static_project.nil?)
        [{
          path: ['sample'],
          message: I18n.t('services.spreadsheet_import.missing_field', index:)
        }]
      elsif response.key?(sample_name)
        [{
          path: ['sample'],
          message: I18n.t('services.samples.batch_import.duplicate_sample_name', index:)
        }]
      end
    end

    def errors_with_project(project_puid, project)
      if project.nil?
        [{
          path: ['project'],
          message: I18n.t('services.samples.batch_import.project_puid_not_found', project_puid: project_puid)
        }]
      elsif !accessible_from_namespace?(project)
        [{
          path: ['project'],
          message: I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                          project_puid: project_puid,
                          namespace: @namespace.full_path)
        }]
      end
    end

    def process_metadata_row(data)
      return if @metadata_fields.nil?

      metadata = {}
      @metadata_fields.each do |metadata_field|
        metadata[metadata_field] = data[metadata_field]
      end
      metadata.compact!

      metadata
    end

    def process_sample_row(name, project, description, metadata)
      sample_params = { name:, description:, include_activity: false }
      sample = Samples::CreateService.new(current_user, project, sample_params).execute

      if sample.persisted?
        Metadata::UpdateService.new(
          sample.project, sample, current_user, { 'metadata' => metadata, include_activity: false }
        ).execute

        add_imported_sample_to_data(sample, project.puid)

        sample
      else
        sample.errors.map do |error|
          {
            path: ['sample', error.attribute.to_s.camelize(:lower)], message: error.message
          }
        end
      end
    end

    def group_namespace_projects
      @group_namespace_projects ||= authorized_scope(
        Project, type: :relation, as: :group_projects, scope_options: {
          group: @namespace,
          minimum_access_level: Member::AccessLevel::MAINTAINER
        }
      )
    end

    def add_imported_sample_to_data(sample, project_puid)
      if @imported_samples_data[:project_data].key?(project_puid)
        @imported_samples_data[:project_data][project_puid] << { sample_name: sample.name, sample_puid: sample.puid }
      else
        @imported_samples_data[:project_data][project_puid] = [{ sample_name: sample.name, sample_puid: sample.puid }]
      end

      return unless @namespace.group_namespace?

      @imported_samples_data[:group_data] << { sample_name: sample.name, sample_puid: sample.puid,
                                               project_puid: project_puid }
    end

    def create_activities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      total_imported_samples_count = 0

      @imported_samples_data[:project_data].each do |project_puid, sample_data|
        imported_samples_count = sample_data.count
        project_ext_details = ExtendedDetail.create!(
          details: {
            imported_samples_data: @imported_samples_data[:project_data][project_puid],
            imported_samples_count:
          }
        )

        project_namespace = Namespaces::ProjectNamespace.find_by(puid: project_puid)
        project_activity = project_namespace.create_activity(
          key: 'namespaces_project_namespace.import_samples.create',
          owner: current_user,
          parameters:
          {
            imported_samples_count: imported_samples_count,
            action: 'project_import_samples'
          }
        )

        project_activity.create_activity_extended_detail(extended_detail_id: project_ext_details.id,
                                                         activity_type: 'project_import_samples')
        total_imported_samples_count += imported_samples_count
      end

      return unless @namespace.group_namespace?

      group_ext_details = ExtendedDetail.create!(
        details: {
          imported_samples_data: @imported_samples_data[:group_data],
          imported_samples_count: total_imported_samples_count
        }
      )
      group_activity = @namespace.create_activity key: 'group.import_samples.create',
                                                  owner: current_user,
                                                  parameters:
                                 {
                                   imported_samples_count: total_imported_samples_count,
                                   action: 'group_import_samples'
                                 }
      group_activity.create_activity_extended_detail(extended_detail_id: group_ext_details.id,
                                                     activity_type: 'group_import_samples')
    end
  end
end
