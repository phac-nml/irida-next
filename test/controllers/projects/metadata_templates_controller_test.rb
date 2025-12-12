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

      assert_response :unprocessable_content

      template_params = { metadata_template: { name: 'New Template' } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_content

      template_params = { metadata_template: { name: 'New Template', fields: [] } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_content

      template_params = { metadata_template: { name: 'New Template', fields: nil } }
      post namespace_project_metadata_templates_path(@namespace.parent, @namespace.project,
                                                     format: :turbo_stream), params: template_params

      assert_response :unprocessable_content
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

      assert_response :unprocessable_content

      template_params = { metadata_template: { fields: [] } }
      put namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream), params: template_params

      assert_response :unprocessable_content
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

      assert_response :success
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

    test 'view metadata template' do
      get namespace_project_metadata_template_path(@namespace.parent, @namespace.project, @metadata_template,
                                                   format: :turbo_stream)

      assert_response :success
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

    test 'accessing metadata templates index on invalid page causes pagy overflow redirect at project level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::OverflowError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_metadata_templates_path(@namespace.parent, @namespace.project, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end
  end
end
