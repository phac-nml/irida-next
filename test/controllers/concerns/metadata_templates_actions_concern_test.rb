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

  test 'group metadata templates new' do
    get new_group_metadata_template_path(@group, format: :turbo_stream)

    assert_response :success
  end

  test 'group metadata templates edit' do
    get edit_group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :success
  end

  test 'group metadata templates show' do
    get group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :success
  end

  test 'group metadata templates create' do
    metadata_template_params = { metadata_template: { name: 'Newest template', fields: %w[field1 field5] } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :success
  end

  test 'group metadata templates create failed' do
    metadata_template_params = { metadata_template: { fields: %w[field1 field5] } }
    post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

    assert_response :unprocessable_entity
  end

  test 'group metadata templates update' do
    metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
    put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
        params: metadata_template_params

    assert_response :success
  end

  test 'group metadata templates update failed' do
    metadata_template_params = { metadata_template: { name: nil } }
    put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
        params: metadata_template_params

    assert_response :unprocessable_entity
  end

  test 'group metadata templates destroy' do
    delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

    assert_response :redirect
  end

  test 'project metadata templates index' do
    get namespace_project_metadata_templates_path(@project_namespace.parent, @project)

    assert_response :success
  end

  test 'project metadata templates new' do
    get new_namespace_project_metadata_template_path(@project_namespace.parent, @project, format: :turbo_stream)

    assert_response :success
  end

  test 'project metadata templates edit' do
    get edit_namespace_project_metadata_template_path(@project_namespace.parent,
                                                      @project, @project_metadata_template,
                                                      format: :turbo_stream)

    assert_response :success
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

  test 'project metadata templates create failed' do
    metadata_template_params = { metadata_template: { name: 'Newest template' } }
    post namespace_project_metadata_templates_path(
      @project_namespace.parent,
      @project, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :unprocessable_entity
  end

  test 'project metadata templates update' do
    metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
    put namespace_project_metadata_template_path(
      @project_namespace.parent,
      @project, @project_metadata_template, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :success
  end

  test 'project metadata templates update failed' do
    metadata_template_params = { metadata_template: { name: nil } }
    put namespace_project_metadata_template_path(
      @project_namespace.parent,
      @project, @project_metadata_template, format: :turbo_stream
    ), params: metadata_template_params

    assert_response :unprocessable_entity
  end

  test 'project metadata templates destroy' do
    delete namespace_project_metadata_template_path(
      @project_namespace.parent,
      @project, @project_metadata_template,
      format: :turbo_stream
    )

    assert_response :redirect
  end
end
