# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class MetadataTemplatesControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @group = groups(:group_one)
        @metadata_template = metadata_templates(:valid_group_metadata_template)
      end

      test 'create metadata template' do
        template_params = { metadata_template: { name: 'New Template', fields: %w[field1 field2] } }
        post group_samples_metadata_templates_path(@group, format: :turbo_stream), params: template_params

        assert_response :success
      end

      test 'update metadata template' do
        template_params = { metadata_template: { name: 'New Name', fields: %w[field1 field2 field3] } }
        put group_samples_metadata_template_path(@group, @metadata_template, format: :turbo_stream),
            params: template_params

        assert_response :success
      end

      test 'delete metadata template' do
        delete group_samples_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

        assert_response :redirect
      end

      test 'view metadata templates listing' do
        get group_samples_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

        assert_response :success
      end

      test 'view metadata templates' do
        get group_samples_metadata_templates_path(@group)

        assert_response :success
      end

      test 'edit metadata template' do
        get edit_group_samples_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

        assert_response :success
      end
    end
  end
end
