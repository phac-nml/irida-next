# frozen_string_literal: true

require 'test_helper'

class MetadataTemplateActionsConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:john_doe)
    @group = groups(:group_one)
    @project = projects(:project1)
    @project_namespace = @project.namespace
    @group_metadata_template = metadata_templates(:valid_group_metadata_template)
    @project_metadata_template = metadata_templates(:valid_metadata_template)
  end

  test 'group metadata templates index' do
    get group_metadata_templates_path(@group)

    assert_response :success
  end

  test 'group metadata templates index unauthorized' do
    sign_in users(:ryan_doe)
    get group_metadata_templates_path(@group)

    assert_response :unauthorized
  end

  test 'group metadata templates new' do
    get new_group_metadata_template_path(@group, format: :turbo_stream)

    assert_response :success
  end

  test 'group metadata templates new unauthorized' do
    sign_in users(:ryan_doe)
    get new_group_metadata_template_path(@group, format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'group metadata templates edit' do
    get edit_group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :success
  end

  test 'group metadata templates edit unauthorized' do
    sign_in users(:ryan_doe)
    get edit_group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'group metadata templates show' do
    get group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :success
  end

  test 'group metadata templates show unauthorized' do
    sign_in users(:ryan_doe)
    get group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'group metadata templates create' do
    metadata_template_params = { metadata_template: { name: 'Newest template', fields: %w[field1 field5] } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :success
  end

  test 'group metadata templates create error' do
    metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { name: 'Newest template' } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { name: 'Newest template', fields: [] } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { name: 'Newest template', fields: nil } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :unprocessable_entity
  end

  test 'group metadata templates create unauthorized' do
    sign_in users(:ryan_doe)
    metadata_template_params = { metadata_template: { name: 'Newest Template', fields: %w[field1 field5] } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :unauthorized
  end

  test 'group metadata templates update' do
    metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
    put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
        params: metadata_template_params

    assert_response :success
  end

  test 'group metadata templates update error' do
    metadata_template_params = { metadata_template: { name: nil } }
    put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
        params: metadata_template_params

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { fields: [] } }
    put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
        params: metadata_template_params

    assert_response :unprocessable_entity
  end

  test 'group metadata templates destroy' do
    delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :redirect
  end

  test 'group metadata templates destroy unauthorized' do
    sign_in users(:ryan_doe)
    delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'project metadata templates index' do
    get namespace_project_metadata_templates_path(@project_namespace.parent, @project)

    assert_response :success
  end

  test 'project metadata templates index unauthorized' do
    sign_in users(:ryan_doe)
    get namespace_project_metadata_templates_path(@project_namespace.parent, @project)

    assert_response :unauthorized
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

  test 'project metadata templates show unauthorized' do
    sign_in users(:ryan_doe)
    get namespace_project_metadata_template_path(@project_namespace.parent,
                                                 @project, @project_metadata_template, format: :turbo_stream)

    assert_response :unauthorized
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

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { fields: %w[field1 field5] } }
    post namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { fields: [] } }
    post namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { fields: nil } }
    post namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :unprocessable_entity
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

    assert_response :unprocessable_entity

    metadata_template_params = { metadata_template: { fields: [] } }
    put namespace_project_metadata_template_path(
      @project_namespace.parent,
      @project, @project_metadata_template, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :unprocessable_entity
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

  test 'project metadata templates destroy' do
    delete namespace_project_metadata_template_path(
      @project_namespace.parent,
      @project, @project_metadata_template,
      format: :turbo_stream
    )

    assert_response :redirect
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

  test 'group metadata templates list with none template' do
    get list_group_metadata_templates_path(@group, metadata_template: 'none', format: :turbo_stream)

    assert_response :success
    assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.none')
  end

  test 'group metadata templates list with all template' do
    get list_group_metadata_templates_path(@group, metadata_template: 'all', format: :turbo_stream)

    assert_response :success
    assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.all')
  end

  test 'group metadata templates list with specific template' do
    get list_group_metadata_templates_path(@group, metadata_template: @group_metadata_template.id,
                                                   format: :turbo_stream)

    assert_response :success
    assert_includes @response.body, @group_metadata_template.name
  end

  test 'group metadata templates list with pagination params' do
    get list_group_metadata_templates_path(@group,
                                           metadata_template: 'all',
                                           limit: 10,
                                           page: 2,
                                           format: :turbo_stream)

    assert_response :success
    # Verify the response includes the paginated content
    assert_includes @response.body, 'turbo-stream'
    assert_includes @response.body, 'metadata_templates_dropdown'
  end

  test 'group metadata templates list unauthorized' do
    sign_in users(:ryan_doe)
    get list_group_metadata_templates_path(@group, metadata_template: 'all', format: :turbo_stream)

    assert_response :unauthorized
  end

  test 'project metadata templates list with none template' do
    get list_namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project,
      metadata_template: 'none',
      format: :turbo_stream
    )

    assert_response :success
    assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.none')
  end

  test 'project metadata templates list with all template' do
    get list_namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project,
      metadata_template: 'all',
      format: :turbo_stream
    )

    assert_response :success
    assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.all')
  end

  test 'project metadata templates list with specific template' do
    get list_namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project,
      metadata_template: @project_metadata_template.id,
      format: :turbo_stream
    )

    assert_response :success
    assert_includes @response.body, @project_metadata_template.name
  end

  test 'project metadata templates list unauthorized' do
    sign_in users(:ryan_doe)
    get list_namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project,
      metadata_template: 'all',
      format: :turbo_stream
    )

    assert_response :unauthorized
  end
end
