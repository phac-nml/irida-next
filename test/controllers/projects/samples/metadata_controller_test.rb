# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class MetadataControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @project1 = projects(:project1)
        @project2 = projects(:project2)
        @namespace = groups(:group_one)
      end

      test 'updating metadata' do
        patch namespace_project_sample_metadata_path(@namespace, @project1, @sample1),
              params: { metadata: { metadata: { key1: 'value1' } }, format: :turbo_stream }
        assert_redirected_to namespace_project_path(@namespace, @project1)
      end
    end
  end
end
