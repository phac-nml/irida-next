# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class FileImportServiceTest < ActiveSupport::TestCase
      def setup
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @project = projects(:project1)
      end

      # bin/rails test test/services/samples/metadata/file_import_service_test.rb

      test 'import sample metadata' do
        params = { file: nil, sample_id_column: nil, ignore_empty_values: nil }
        response = Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                            params).execute

        assert_equal('DONE', response)
      end

      test 'import sample metadata with permission' do
        assert_authorized_to(:update_sample?, @project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          Samples::Metadata::FileImportService.new(@project, @john_doe,
                                                   {}).execute
        end
      end

      test 'import sample metadata without permission' do
        assert_raises(ActionPolicy::Unauthorized) do
          Samples::Metadata::FileImportService.new(@project, @jane_doe,
                                                   {}).execute
        end
      end
    end
  end
end
