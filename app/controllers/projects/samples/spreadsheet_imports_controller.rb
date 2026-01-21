# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Spreadsheet Import Controller
    class SpreadsheetImportsController < Projects::ApplicationController
      include SampleSpreadsheetImportActions

      respond_to :turbo_stream

      private

      def namespace
        @namespace = @project.namespace
      end

      def spreadsheet_import_params
        params.expect(spreadsheet_import: [:file, :sample_name_column, :sample_description_column,
                                           { metadata_fields: [] }])
      end
    end
  end
end
