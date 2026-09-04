# frozen_string_literal: true

require 'test_helper'

module Projects
  class MetadataTemplatesTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)
      @project = projects(:project1)
      @project_namespace = @project.namespace
      @project_metadata_template = metadata_templates(:valid_metadata_template)
      @sorted_project = projects(:john_doe_project2)
      @project_metadata_template1 = metadata_templates(:project2_metadata_template1)
      @project_metadata_template2 = metadata_templates(:project2_metadata_template2)
    end

    test 'project metadata templates index' do
      get namespace_project_metadata_templates_path(@project_namespace.parent, @project)

      assert_response :success

      w3c_validate 'Project Metadata Templates Page'
    end

    test 'project metadata templates new' do
      get new_namespace_project_metadata_template_path(@project_namespace.parent, @project, format: :turbo_stream)

      assert_response :success
    end

    test 'project metadata templates new unauthorized' do
      sign_in users(:ryan_doe)
      get new_namespace_project_metadata_template_path(@project_namespace.parent, @project, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'project metadata templates edit' do
      get edit_namespace_project_metadata_template_path(@project_namespace.parent,
                                                        @project, @project_metadata_template,
                                                        format: :turbo_stream)

      assert_response :success
    end

    test 'project metadata templates edit unauthorized' do
      sign_in users(:ryan_doe)
      get edit_namespace_project_metadata_template_path(@project_namespace.parent,
                                                        @project, @project_metadata_template,
                                                        format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'project metadata templates show' do
      get namespace_project_metadata_template_path(@project_namespace.parent,
                                                   @project, @project_metadata_template, format: :turbo_stream)

      assert_response :success
    end

    test 'project metadata templates create' do
      metadata_template_params = { metadata_template: { name: 'Newest template', fields: %w[field1 field5] } }
      post namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :success
    end

    test 'project metadata templates create error' do
      metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
      post namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { fields: %w[field1 field5] } }
      post namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { fields: [] } }
      post namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { fields: nil } }
      post namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :bad_request
    end

    test 'project metadata templates create unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'Newest template', fields: %w[field1 field5] } }
      post namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unauthorized
    end

    test 'project metadata templates create with invalid params' do
      metadata_template_params = { metadata_template: { name: '', fields: [] } }
      post namespace_project_metadata_templates_path(@project_namespace.parent, @project, format: :turbo_stream),
           params: metadata_template_params

      assert_response :unprocessable_content
    end

    test 'project metadata templates update' do
      metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
      put namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :success
    end

    test 'project metadata templates update error' do
      metadata_template_params = { metadata_template: { name: nil } }
      put namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { fields: [] } }
      put namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content
    end

    test 'project metadata templates update with invalid params' do
      metadata_template_params = { metadata_template: { name: '', fields: [] } }
      put namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project,
        @project_metadata_template,
        format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content
    end

    test 'project metadata templates update unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
      put namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unauthorized
    end

    test 'project metadata templates update renders translated error when service fails with no model errors' do
      MetadataTemplates::UpdateService.any_instance.stubs(:execute).returns(false)

      metadata_template_params = { metadata_template: { name: 'Valid Name', fields: %w[field1] } }
      put namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content
      assert_select "div[data-controller='viral--flash']",
                    text: /#{Regexp.escape(I18n.t('concerns.metadata_template_actions.update.error',
                                                  template_name: @project_metadata_template.name))}/
    end

    test 'project metadata templates destroy' do
      delete namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template,
        format: :turbo_stream
      )

      assert_response :success
    end

    test 'project metadata templates destroy unauthorized' do
      sign_in users(:ryan_doe)
      delete namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project, @project_metadata_template,
        format: :turbo_stream
      )

      assert_response :unauthorized
    end

    test 'project metadata templates destroy renders error from error_message when not deleted' do
      MetadataTemplates::DestroyService.any_instance.stubs(:execute).returns(nil)
      Projects::MetadataTemplatesController.any_instance.stubs(:error_message)
                                           .returns('Destroy failed from error_message')

      delete namespace_project_metadata_template_path(
        @project_namespace.parent,
        @project,
        @project_metadata_template,
        format: :turbo_stream
      )

      assert_response :unprocessable_content
      assert_select "div[data-controller='viral--flash']", text: /Destroy failed from error_message/
    end

    test 'project metadata templates list with none template' do
      get list_namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project,
        metadata_template: 'none'
      )

      assert_response :success
      assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.none')
    end

    test 'project metadata templates list with all template' do
      get list_namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project,
        metadata_template: 'all'
      )

      assert_response :success
      assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.all')
    end

    test 'project metadata templates list with specific template' do
      get list_namespace_project_metadata_templates_path(
        @project_namespace.parent,
        @project,
        metadata_template: @project_metadata_template.id
      )

      assert_response :success
      assert_includes @response.body, @project_metadata_template.name
    end

    test 'project metadata templates index with pagination and sorting' do
      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@project_metadata_template1.name, @project_metadata_template2.name)

      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project,
                                                    params: { q: { s: 'name desc' } })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(@project_metadata_template2.name, @project_metadata_template1.name)

      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project,
                                                    params: { q: { s: 'created_by_email asc' } })
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(@project_metadata_template2.name, @project_metadata_template1.name)

      get namespace_project_metadata_templates_path(@sorted_project.namespace.parent, @sorted_project,
                                                    params: { q: { s: 'created_by_email desc' } })
      assert_response :success
      assert_sort_state(3, 'descending')
      assert_first_rows_include(@project_metadata_template1.name, @project_metadata_template2.name)
    end

    test 'accessing metadata templates index on invalid page causes pagy overflow redirect at project level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_metadata_templates_path(@project_namespace.parent, @project_namespace.project, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end

    test 'projects metadata templates controller metadata_templates_path delegates to project route helper' do
      controller = Projects::MetadataTemplatesController.new
      controller.stubs(:namespace_project_metadata_templates_path).returns('/projects/project-one/metadata_templates')

      assert_equal '/projects/project-one/metadata_templates', controller.send(:metadata_templates_path)
    end
  end
end
