# frozen_string_literal: true

require 'roo'

module Samples
  # Service used to batch create samples via a file
  class BatchFileImportService < BaseService
    SampleFileImportError = Class.new(StandardError)

    def initialize(namespace, user = nil, params = {})
      super(user, params)
      @namespace = namespace
      @file = params[:file]
      @sample_name_column = params[:sample_name_column]
      @project_puid_column = params[:project_puid_column]
      @sample_description_column = params[:sample_description_column]
      @spreadsheet = nil
      @headers = nil
    end

    def execute
      authorize! @namespace, to: :update_sample_metadata?

      validate_sample_name_column

      validate_file

      perform_file_import
    rescue Samples::BatchFileImportService::SampleFileImportError => e
      @namespace.errors.add(:base, e.message)
      {}
    end

    private

    def validate_sample_name_column
      return unless @sample_name_column.nil?

      raise SampleFileImportError,
            I18n.t('services.samples.metadata.import_file.empty_sample_id_column')
    end

    def validate_file_extension
      file_extension = File.extname(@file).downcase

      return file_extension if %w[.csv .tsv .xls .xlsx].include?(file_extension)

      raise SampleFileImportError,
            I18n.t('services.samples.metadata.import_file.invalid_file_extension')
    end

    def validate_file_headers
      duplicate_headers = @headers.find_all { |header| @headers.count(header) > 1 }.uniq
      unless duplicate_headers.empty?
        raise SampleFileImportError,
              I18n.t('services.samples.metadata.import_file.duplicate_column_names')
      end

      unless @headers.include?(@sample_name_column)
        raise SampleFileImportError,
              I18n.t('services.samples.metadata.import_file.missing_sample_id_column')
      end

      # TODO: check if we have a project puid

      # return if @headers.count { |header| header != @sample_name_column }.positive?

      # raise SampleFileImportError,
      #       I18n.t('services.samples.metadata.import_file.missing_metadata_column')
    end

    def validate_file_rows
      # Should have at least 2 rows
      first_row = @spreadsheet.row(2)
      return unless first_row.compact.empty?

      raise SampleFileImportError,
            I18n.t('services.samples.metadata.import_file.missing_metadata_row')
    end

    def validate_file
      if @file.nil?
        raise SampleFileImportError,
              I18n.t('services.samples.metadata.import_file.empty_file')
      end

      extension = validate_file_extension

      @spreadsheet = if extension.eql? '.tsv'
                       Roo::CSV.new(@file, csv_options: { col_sep: "\t" })
                     else
                       Roo::Spreadsheet.open(@file)
                     end

      # # filter for ',' and '\t' to skip empty lines with column seperators
      # empty_row_regex = /^(?:,*\s*)+$/
      # @spreadsheet = if extension.eql? '.tsv'
      #                   Roo::CSV.new(@file,
      #                               csv_options: { skip_blanks: true, skip_lines: empty_row_regex, col_sep: "\t" })
      #                 elsif extension.eql? '.csv'
      #                   Roo::CSV.new(@file, csv_options: { skip_blanks: true, skip_lines: empty_row_regex })
      #                 else
      #                   Roo::Spreadsheet.open(@file)
      #                 end

      @headers = @spreadsheet.row(1).compact

      validate_file_headers

      validate_file_rows
    end

    def perform_file_import
      response = {}
      parse_settings = @headers.zip(@headers).to_h

      @spreadsheet.each_with_index(parse_settings) do |data, index|
        next unless index.positive?

        # TODO: next when all data is nil (empty line)

        # TODO: handle metadata

        sample_name = data[@sample_name_column]
        project_puid = data[@project_puid_column]
        description = data[@sample_description_column]

        # TODO: catch exceptions here
        project = Namespaces::ProjectNamespace.find_by(puid: project_puid)&.project

        response[sample_name] = process_sample_row(sample_name, project, description)
      rescue ActiveRecord::RecordNotFound
        project.errors.add(:sample, error_message(sample_name))
      end
      response
    end

    def error_message(sample_id) # TODO: remove
      if @namespace.type == 'Group'
        I18n.t('services.samples.metadata.import_file.sample_not_found_within_group', sample_puid: sample_id)
      else
        I18n.t('services.samples.metadata.import_file.sample_not_found_within_project', sample_puid: sample_id)
      end
    end

    def process_sample_row(name, project, description)
      sample_params = { name:, description: }
      sample = Samples::CreateService.new(current_user, project, sample_params).execute

      if sample.persisted?
        sample
      else
        sample.errors.map do |error| # TODO: rework this error
          {
            path: ['sample', error.attribute.to_s.camelize(:lower)],
            message: error.message
          }
        end
      end
    end

    # def find_sample(sample_id)
    #   if @namespace.type == 'Group'
    #     authorized_scope(Sample, type: :relation, as: :namespace_samples,
    #                              scope_options: { namespace: @namespace,
    #                                               minimum_access_level: Member::AccessLevel::MAINTAINER })
    #       .find_by!(puid: sample_id)
    #   else
    #     project = @namespace.project
    #     if Irida::PersistentUniqueId.valid_puid?(sample_id, Sample)
    #       Sample.find_by!(puid: sample_id, project_id: project.id)
    #     else
    #       Sample.find_by!(name: sample_id, project_id: project.id)
    #     end
    #   end
    # end
  end
end
