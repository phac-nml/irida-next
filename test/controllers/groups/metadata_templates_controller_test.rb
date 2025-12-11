# frozen_string_literal: true

require 'test_helper'

module Groups
  class MetadataTemplatesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
      @metadata_template = metadata_templates(:valid_group_metadata_template)
    end

    test 'create metadata template' do
      template_params = { metadata_template: { name: 'New Template', fields: %w[field1 field2] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params

      assert_response :success
    end

    test 'create metadata template error' do
      template_params = { metadata_template: { name: '', fields: %w[field1 field2] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params

      assert_response :unprocessable_content

      template_params = { metadata_template: { name: 'New Template' } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params

      assert_response :unprocessable_content

      template_params = { metadata_template: { name: 'New Template', fields: [] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params

      assert_response :unprocessable_content

      template_params = { metadata_template: { name: 'New Template', fields: nil } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params

      assert_response :unprocessable_content
    end

    test 'create metadata template unauthorized' do
      sign_in users(:ryan_doe)
      template_params = { metadata_template: { name: 'New Template', fields: %w[field1 field2] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params

      assert_response :unauthorized
    end

    test 'update metadata template' do
      template_params = { metadata_template: { name: 'New Name', fields: %w[field1 field2 field3] } }
      put group_metadata_template_path(@group, @metadata_template, format: :turbo_stream),
          params: template_params

      assert_response :success
    end

    test 'update metadata template error' do
      template_params = { metadata_template: { name: '' } }
      put group_metadata_template_path(@group, @metadata_template, format: :turbo_stream),
          params: template_params

      assert_response :unprocessable_content

      template_params = { metadata_template: { fields: [] } }
      put group_metadata_template_path(@group, @metadata_template, format: :turbo_stream),
          params: template_params

      assert_response :unprocessable_content
    end

    test 'update metadata template unauthorized' do
      sign_in users(:ryan_doe)
      template_params = { metadata_template: { name: 'New Name', fields: %w[field1 field2 field3] } }
      put group_metadata_template_path(@group, @metadata_template, format: :turbo_stream),
          params: template_params

      assert_response :unauthorized
    end

    test 'delete metadata template' do
      delete group_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

      assert_response :success
    end

    test 'delete metadata template unauthorized' do
      sign_in users(:ryan_doe)
      delete group_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'view metadata templates listing' do
      get group_metadata_templates_path(@group)

      assert_response :success

      w3c_validate 'Group Metadata Templates Page'
    end

    test 'view metadata template' do
      get group_metadata_template_path(@group, @metadata_template,
                                       format: :turbo_stream)

      assert_response :success
    end

    test 'edit metadata template' do
      get edit_group_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

      assert_response :success
    end

    test 'edit metadata template unauthorized' do
      sign_in users(:ryan_doe)
      get edit_group_metadata_template_path(@group, @metadata_template, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'accessing metadata templates index on invalid page causes pagy overflow redirect at group level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::OverflowError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get group_metadata_templates_path(@group, page: 50)

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
