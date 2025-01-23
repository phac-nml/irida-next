# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class MetadataTemplatesControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @project = projects(:project1)
        @project29 = projects(:project29)
        @namespace = @project.namespace
        @metadata_template = metadata_templates(:valid_metadata_template)
      end

      test 'create metadata template' do
        template_params = { metadata_template: { name: 'New Template', fields: %w[field1 field2] } }
        post namespace_project_samples_metadata_templates_path(@namespace.parent, @namespace.project,
                                                               format: :turbo_stream), params: template_params

        assert_response :success
      end

      test 'update metadata template' do
        template_params = { metadata_template: { name: 'New Name', fields: %w[field4 field5 field6] } }
        put namespace_project_samples_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                             format: :turbo_stream), params: template_params

        assert_response :success
      end

      test 'delete metadata template' do
        delete namespace_project_samples_metadata_template_path(@namespace.parent, @namespace.project,
                                                                @metadata_template, format: :turbo_stream)

        assert_response :success
      end

      test 'view metadata templates listing' do
        get namespace_project_samples_metadata_templates_path(@namespace.parent, @namespace.project)

        assert_response :success
      end

      test 'view metadata template' do
        get namespace_project_samples_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                             format: :turbo_stream)

        assert_response :success
      end

      test 'edit metadata template' do
        get edit_namespace_project_samples_metadata_template_path(@namespace.parent, @namespace.project,
                                                                  @metadata_template, format: :turbo_stream)

        assert_response :success
      end
    end
  end
end
