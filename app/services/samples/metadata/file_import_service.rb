# frozen_string_literal: true

module Samples
  module Metadata
    # Service used to import sample metadata via a file
    class FileImportService < BaseService
      SampleMetadataFileImportError = Class.new(StandardError)

      def initialize(project, user = nil, params = {})
        super(user, params)
        @project = project
        @file = params['file']
        @sample_id_column = params['sample_id_column']
        @ignore_empty_values = params['ignore_empty_values']
      end

      def execute
        authorize! @project, to: :update_sample?

        pp @project
        pp @file
        pp @sample_id_column
        pp @ignore_empty_values

        # TODO: create validate_file
        # TODO: call Samples::Metadata::UpdateService

        'DONE'
      end
    end
  end
end
