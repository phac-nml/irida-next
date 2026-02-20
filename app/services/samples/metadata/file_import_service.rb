# frozen_string_literal: true

require 'roo'

module Samples
  module Metadata
    # Service used to import sample metadata via a file
    class FileImportService < BaseSpreadsheetImportService
      def initialize(namespace, user = nil, blob_id = nil, params = {})
        @sample_id_column = params[:sample_id_column]
        @selected_headers = params[:metadata_columns] || []
        @ignore_empty_values = params[:ignore_empty_values]
        super(namespace, user, blob_id, [@sample_id_column], 1, params)
      end

      def execute(broadcast_target = nil)
        begin
          authorize! @namespace, to: :update_sample_metadata?
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

      def perform_file_import(broadcast_target) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        bulk_metadata_payload = {}
        response = {}
        headers = retrieve_headers
        parse_settings = headers.zip(headers).to_h
        # minus 1 to exclude header
        percentage_denominator = (@spreadsheet.count - 1) * 1.05
        @spreadsheet.each_with_index(parse_settings) do |metadata, index|
          next unless index.positive?

          update_progress_bar(index, percentage_denominator, broadcast_target)

          sample_id = metadata[@sample_id_column].to_s
          metadata.delete(@sample_id_column)
          metadata.compact! if @ignore_empty_values

          bulk_metadata_payload[sample_id] = metadata
        end

        BulkUpdateService.new(@namespace, bulk_metadata_payload, @selected_headers, current_user).execute
        update_progress_bar(percentage_denominator, percentage_denominator, broadcast_target)
        response
      end

      private

      def retrieve_headers
        headers = [*@selected_headers, *@sample_id_column]
        strip_headers(headers)
      end
    end
  end
end
