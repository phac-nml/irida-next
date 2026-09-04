# frozen_string_literal: true

require 'test_helper'

module Groups
  class MetadataTemplatesTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
      @group_metadata_template = metadata_templates(:valid_group_metadata_template)
      @sorted_group = groups(:group_two)
      @group_metadata_template1 = metadata_templates(:group_two_metadata_template1)
      @group_metadata_template2 = metadata_templates(:group_two_metadata_template2)
    end

    test 'group metadata templates index' do
      get group_metadata_templates_path(@group)

      assert_response :success

      w3c_validate 'Group Metadata Templates Page'
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

    test 'group metadata templates create' do
      metadata_template_params = { metadata_template: { name: 'Newest template', fields: %w[field1 field5] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :success
    end

    test 'group metadata templates create error' do
      metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { name: 'Newest template' } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { name: 'Newest template', fields: [] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { name: 'Newest template', fields: nil } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :unprocessable_content
    end

    test 'group metadata templates create unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'Newest Template', fields: %w[field1 field5] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :unauthorized
    end

    test 'group metadata templates create with invalid params' do
      metadata_template_params = { metadata_template: { name: '', fields: [] } }
      post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params

      assert_response :unprocessable_content
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

      assert_response :unprocessable_content

      metadata_template_params = { metadata_template: { fields: [] } }
      put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
          params: metadata_template_params

      assert_response :unprocessable_content
    end

    test 'group metadata templates update with invalid params' do
      metadata_template_params = { metadata_template: { name: '', fields: [] } }
      put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
          params: metadata_template_params

      assert_response :unprocessable_content
    end

    test 'group metadata templates update renders translated error when service fails with no model errors' do
      MetadataTemplates::UpdateService.any_instance.stubs(:execute).returns(false)

      metadata_template_params = { metadata_template: { name: 'Valid Name', fields: %w[field1] } }
      put group_metadata_template_path(
        @group, @group_metadata_template, format: :turbo_stream
      ), params: metadata_template_params

      assert_response :unprocessable_content
      assert_select "div[data-controller='viral--flash']",
                    text: /#{Regexp.escape(I18n.t('concerns.metadata_template_actions.update.error',
                                                  template_name: @group_metadata_template.name))}/
    end

    test 'group metadata templates destroy' do
      delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

      assert_response :success
    end

    test 'group metadata templates destroy unauthorized' do
      sign_in users(:ryan_doe)
      delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

      assert_response :unauthorized
    end

    test 'group metadata templates destroy renders error from error_message when not deleted' do
      metadata_template = metadata_templates(:group_one_metadata_template0)
      MetadataTemplates::DestroyService.any_instance.stubs(:execute).returns(nil)
      Groups::MetadataTemplatesController.any_instance.stubs(:error_message)
                                         .returns('Destroy failed from error_message')

      delete group_metadata_template_path(@group, metadata_template, format: :turbo_stream)

      assert_response :unprocessable_content
      assert_select "div[data-controller='viral--flash']", text: /Destroy failed from error_message/
    end

    test 'group metadata templates list with none template' do
      get list_group_metadata_templates_path(@group, metadata_template: 'none')

      assert_response :success
      assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.none')
    end

    test 'group metadata templates list with all template' do
      get list_group_metadata_templates_path(@group, metadata_template: 'all')

      assert_response :success
      assert_includes @response.body, I18n.t('shared.samples.metadata_templates.fields.all')
    end

    test 'group metadata templates list with specific template' do
      get list_group_metadata_templates_path(@group, metadata_template: @group_metadata_template.id)

      assert_response :success
      assert_includes @response.body, @group_metadata_template.name
    end

    test 'group metadata templates list with pagination params' do
      get list_group_metadata_templates_path(@group,
                                             metadata_template: 'all',
                                             limit: 1,
                                             page: 2)

      assert_response :success
      # Verify the response includes the paginated content
      assert_includes @response.body, 'turbo-stream'
      assert_includes @response.body, 'metadata_templates_dropdown'
    end

    test 'group metadata templates index with pagination and sorting' do
      get group_metadata_templates_path(@sorted_group)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@group_metadata_template1.name, @group_metadata_template2.name)

      get group_metadata_templates_path(@sorted_group, params: { q: { s: 'name desc' } })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(@group_metadata_template2.name, @group_metadata_template1.name)

      get group_metadata_templates_path(@sorted_group, params: { q: { s: 'created_by_email asc' } })
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(@group_metadata_template1.name, @group_metadata_template2.name)

      get group_metadata_templates_path(@sorted_group, params: { q: { s: 'created_by_email desc' } })
      assert_response :success
      assert_sort_state(3, 'descending')
      assert_first_rows_include(@group_metadata_template2.name, @group_metadata_template1.name)
    end

    test 'accessing metadata templates index on invalid page causes pagy overflow redirect at group level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
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

    test 'groups metadata templates controller metadata_templates_path delegates to group route helper' do
      controller = Groups::MetadataTemplatesController.new
      controller.stubs(:group_metadata_templates_path).returns('/groups/group-one/metadata_templates')

      assert_equal '/groups/group-one/metadata_templates', controller.send(:metadata_templates_path)
    end
  end
end
