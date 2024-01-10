# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class FileImportServiceTest < ActiveSupport::TestCase
      def setup
        @user = users(:john_doe)
        @project = projects(:project1)
      end

      # bin/rails test test/services/samples/metadata/file_import_service_test.rb

      test 'import sample metadata with permission' do
        params = { file: nil, sample_id_column: nil, ignore_empty_values: nil }
        response = Samples::Metadata::FileImportService.new(@project, @user,
                                                            params).execute

        assert_equal('DONE', response)
      end
    end
  end
end
