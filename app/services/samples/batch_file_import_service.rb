# frozen_string_literal: true

require 'roo'

module Samples
  # Service used to batch create samples via a file
  class BatchFileImportService < BaseSpreadsheetImportService # rubocop:disable Metrics/ClassLength
    def initialize(namespace, user = nil, blob_id = nil, params = {})
      @sample_name_column = params[:sample_name_column]
      @project_puid_column = params[:project_puid_column]
      @sample_description_column = params[:sample_description_column]
      required_headers = [@sample_name_column, @project_puid_column]
      @project_samples_count = {}
      @project_puid_map = {}
      super(namespace, user, blob_id, required_headers, 0, params)
    end

    def execute
      authorize! @namespace, to: :import_samples_and_metadata?
      validate_file
      perform_file_import
    rescue FileImportError => e
      @namespace.errors.add(:base, e.message)
      {}
    end

    protected

    def perform_file_import # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      response = {}
      parse_settings = @headers.zip(@headers).to_h

      @spreadsheet.each_with_index(parse_settings) do |data, index|
        next unless index.positive?

        sample_name = data[@sample_name_column]
        project_puid = data[@project_puid_column]
        description = data[@sample_description_column]
        metadata = process_metadata_row(data)

        error = errors_on_sample_row(sample_name, project_puid, response, index)
        unless error.nil?
          response["index #{index}"] = error
          next
        end

        project = Namespaces::ProjectNamespace.find_by(puid: project_puid)&.project
        error = errors_with_project(project_puid, project)
        unless error.nil?
          response[sample_name] = error
          next
        end

        response[sample_name] = process_sample_row(sample_name, project, description, metadata)
      end
      cleanup_files

      create_activities unless @project_samples_count.empty?

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
      if sample_name.nil? || project_puid.nil?
        {
          path: ['sample'],
          message: I18n.t('services.spreadsheet_import.missing_field', index:)
        }
      elsif response.key?(sample_name)
        {
          path: ['sample'],
          message: I18n.t('services.samples.batch_import.duplicate_sample_name', index:)
        }
      end
    end

    def errors_with_project(project_puid, project)
      if project.nil?
        {
          path: ['project'],
          message: I18n.t('services.samples.batch_import.project_puid_not_found', project_puid: project_puid)
        }
      elsif !accessible_from_namespace?(project)
        {
          path: ['project'],
          message: I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                          project_puid: project_puid,
                          namespace: @namespace.full_path)
        }
      end
    end

    def process_metadata_row(data)
      metadata = data.except(@sample_name_column, @project_puid_column, @sample_description_column)
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

        increment_sample_count(project)

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

    def create_activities # rubocop:disable Metrics/MethodLength
      total_sample_count = 0
      @project_samples_count.each do |project_puid, sample_count|
        @project_puid_map[project_puid].namespace.create_activity(
          key: 'namespaces_project_namespace.import_samples.create',
          owner: current_user,
          parameters:
          {
            imported_samples_count: sample_count,
            action: 'import_samples'
          }
        )
        total_sample_count += sample_count
      end

      return unless @namespace.group_namespace? && total_sample_count.positive?

      @namespace.create_activity key: 'group.import_samples.create',
                                 owner: current_user,
                                 parameters:
                                 {
                                   imported_samples_count: total_sample_count,
                                   action: 'import_samples'
                                 }
    end

    def increment_sample_count(project)
      project_puid = project.puid
      @project_samples_count[project_puid] = if @project_samples_count.key?(project_puid)
                                               @project_samples_count[project_puid] + 1
                                             else
                                               @project_puid_map[project_puid] = project
                                               1
                                             end
    end
  end
end
