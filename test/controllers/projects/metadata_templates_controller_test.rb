# frozen_string_literal: true

require 'test_helper'

module Projects
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
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :success
    end

    test 'create metadata template error' do
      template_params = { metadata_template: { name: '', fields: %w[field1 field2] } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_entity

      template_params = { metadata_template: { name: 'New Template' } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_entity

      template_params = { metadata_template: { name: 'New Template', fields: [] } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_entity

      template_params = { metadata_template: { name: 'New Template', fields: nil } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_entity
    end

    test 'create metadata template unauthorized' do
      sign_in users(:ryan_doe)
      template_params = { metadata_template: { name: '', fields: %w[field1 field2] } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unauthorized
    end

    test 'update metadata template' do
      template_params = { metadata_template: { name: 'New Name', fields: %w[field4 field5 field6] } }
      put namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream), params: template_params

      assert_response :success
    end

    test 'update metadata template error' do
      template_params = { metadata_template: { name: '' } }
      put namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream), params: template_params

      assert_response :unprocessable_entity

      template_params = { metadata_template: { fields: [] } }
      put namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream), params: template_params

      assert_response :unprocessable_entity
    end

    test 'update metadata template unauthorized' do
      sign_in users(:ryan_doe)
      template_params = { metadata_template: { name: 'New Name', fields: %w[field4 field5 field6] } }
      put namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream), params: template_params

      assert_response :unauthorized
    end

    test 'delete metadata template' do
      delete namespace_project_metadata_template_path(@namespace.parent, @namespace.project,
                                                      @metadata_template, format: :turbo_stream)

      assert_response :redirect
    end

    test 'delete metadata template unauthorized' do
      sign_in users(:ryan_doe)
      delete namespace_project_metadata_template_path(@namespace.parent, @namespace.project,
                                                      @metadata_template, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'view metadata templates listing' do
      get namespace_project_metadata_templates_path(@namespace.parent, @namespace.project)

      assert_response :success
    end

    test 'view metadata templates listing unauthorized' do
      sign_in users(:ryan_doe)
      get namespace_project_metadata_templates_path(@namespace.parent, @namespace.project)

      assert_response :success
    end

    test 'view metadata template' do
      get namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream)

      assert_response :success
    end

    test 'view metadata template unauthorized' do
      sign_in users(:ryan_doe)
      get namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'edit metadata template' do
      get edit_namespace_project_metadata_template_path(@namespace.parent, @namespace.project,
                                                        @metadata_template, format: :turbo_stream)

      assert_response :success
    end

    test 'edit metadata template unauthorized' do
      sign_in users(:ryan_doe)
      get edit_namespace_project_metadata_template_path(@namespace.parent, @namespace.project,
                                                        @metadata_template, format: :turbo_stream)

      assert_response :unauthorized
    end
  end
end
