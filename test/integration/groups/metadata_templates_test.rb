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

      assert_select 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_select 'p', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_select 'table thead tr th', count: 6
      assert_select 'table tbody tr', count: @group.metadata_templates.count

      @group.metadata_templates.each do |metadata_template|
        assert_select 'table tbody tr td:nth-child(1)', text: metadata_template.name
      end
    end

    test 'group metadata templates new' do
      get new_group_metadata_template_path(@group, format: :turbo_stream)

      assert_response :success

      assert_select 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_select 'dialog h2', text: I18n.t('metadata_templates.form.details_heading')
      assert_select 'dialog h2', text: I18n.t('metadata_templates.form.metadata')

      available_label_id = 'available-list-list-label'
      selected_label_id = 'selected-list-list-label'
      assert_select "ul[aria-labelledby='#{available_label_id}'] li", count: @group.metadata_fields.count
      assert_select "ul[aria-labelledby='#{selected_label_id}'] li", count: 0
      @group.metadata_fields.each do |field|
        assert_select "ul[aria-labelledby='#{available_label_id}'] li", text: field
      end
    end

    test 'group metadata templates new unauthorized' do
      sign_in users(:ryan_doe)
      get new_group_metadata_template_path(@group, format: :turbo_stream)

      assert_response :unauthorized

      assert_includes @response.body,
                      I18n.t('action_policy.policy.group.create_metadata_templates?', name: @group.name)
    end

    test 'group metadata templates edit' do
      get edit_group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

      assert_response :success

      assert_select 'dialog h1', text: I18n.t('metadata_templates.edit_template_dialog.title')
      assert_select "input[value='#{@group_metadata_template.name}']"
      assert_select 'textarea', text: @group_metadata_template.description

      available_label_id = 'available-list-list-label'
      selected_label_id = 'selected-list-list-label'
      assert_select "ul[aria-labelledby='#{available_label_id}'] li",
                    count: @group.metadata_fields.count - @group_metadata_template.fields.count
      assert_select "ul[aria-labelledby='#{selected_label_id}'] li", count: @group_metadata_template.fields.count

      unselected_fields = @group.metadata_fields.reject do |field|
        @group_metadata_template.fields.include? field
      end
      unselected_fields.each do |field|
        assert_select "ul[aria-labelledby='#{available_label_id}'] li", text: field
      end
    end

    test 'group metadata templates edit unauthorized' do
      sign_in users(:ryan_doe)
      get edit_group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)

      assert_response :unauthorized

      assert_includes @response.body, I18n.t('action_policy.unauthorized')
    end

    test 'group metadata templates create' do
      new_name = 'Newest template'
      metadata_template_params = { metadata_template: { name: new_name, fields: %w[field1 field5] } }
      assert_difference('MetadataTemplate.count', 1) do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params
      end
      assert_response :success
      assert_includes @response.body, I18n.t('concerns.metadata_template_actions.create.success',
                                             template_name: new_name)

      get group_metadata_templates_path(@group)
      assert_response :success
      assert_select 'table tbody tr td:nth-child(1)', text: new_name
    end

    test 'group metadata templates create error' do
      metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
      assert_no_difference('MetadataTemplate.count') do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:name),
                   message: I18n.t(:'errors.messages.blank'))
      assert_select "div[class='form-field invalid']"

      metadata_template_params = { metadata_template: { name: 'Newest template', fields: [] } }
      assert_no_difference('MetadataTemplate.count') do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:fields),
                   message: I18n.t('activerecord.errors.models.metadata_template.attributes.fields.min_length', min: 1))
    end

    test 'group metadata templates create unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'Newest Template', fields: %w[field1 field5] } }
      assert_no_difference('MetadataTemplate.count') do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: metadata_template_params
      end

      assert_response :unauthorized

      assert_includes @response.body,
                      I18n.t('action_policy.policy.group.create_metadata_templates?', name: @group.name)
    end

    test 'group metadata templates update' do
      new_name = 'This is the new template'
      metadata_template_params = { metadata_template: { name: new_name, fields: %w[field6 field10] } }
      assert_changes -> { @group_metadata_template.reload.name }, from: @group_metadata_template.name, to: new_name do
        put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
            params: metadata_template_params
      end

      assert_response :success

      assert_includes @response.body, I18n.t(
        :'concerns.metadata_template_actions.update.success',
        template_name: new_name
      )

      assert_select "tr#metadata_template_#{@group_metadata_template.id}" do
        assert_select 'td', text: new_name
        assert_select 'button', text: I18n.t('common.actions.edit'), focused: true
      end
    end

    test 'group metadata templates update error' do
      metadata_template_params = { metadata_template: { name: '', fields: %w[field1 field5] } }
      assert_no_changes -> { @group_metadata_template.reload } do
        put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
            params: metadata_template_params
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: MetadataTemplate.human_attribute_name(:name),
                   message: I18n.t(:'errors.messages.blank'))
      assert_select "div[class='form-field invalid']"

      metadata_template_params = { metadata_template: { name: 'Newest template', fields: [] } }
      assert_no_changes -> { @group_metadata_template.reload } do
        put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
            params: metadata_template_params
      end

      assert_select 'a', text:
        I18n.t(:'errors.format',
               attribute: MetadataTemplate.human_attribute_name(:fields),
               message: I18n.t('activerecord.errors.models.metadata_template.attributes.fields.min_length', min: 1))

      assert_response :unprocessable_content
    end

    test 'group metadata templates update unauthorized' do
      sign_in users(:ryan_doe)
      metadata_template_params = { metadata_template: { name: 'This is the new template', fields: %w[field6 field10] } }
      assert_no_changes -> { @group_metadata_template.reload } do
        put group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream),
            params: metadata_template_params
      end

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div', "#{I18n.t('common.statuses.error')}: #{I18n.t('action_policy.unauthorized')}"
      end
    end

    test 'group metadata templates update renders translated error when service fails with no model errors' do
      MetadataTemplates::UpdateService.any_instance.stubs(:execute).returns(false)

      metadata_template_params = { metadata_template: { name: 'Valid Name', fields: %w[field1] } }
      assert_no_changes -> { @group_metadata_template.reload } do
        put group_metadata_template_path(
          @group, @group_metadata_template, format: :turbo_stream
        ), params: metadata_template_params
      end

      assert_response :unprocessable_content
      assert_select "div[data-controller='viral--flash']",
                    text: /#{Regexp.escape(I18n.t('concerns.metadata_template_actions.update.error',
                                                  template_name: @group_metadata_template.name))}/
    end

    test 'group metadata templates destroy' do
      assert_difference('MetadataTemplate.count', -1) do
        delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)
      end

      assert_response :success

      assert_includes @response.body, I18n.t(
        :'concerns.metadata_template_actions.destroy.success',
        template_name: @group_metadata_template.name
      )
    end

    test 'group metadata templates destroy unauthorized' do
      sign_in users(:ryan_doe)
      assert_no_difference('MetadataTemplate.count') do
        delete group_metadata_template_path(@group, @group_metadata_template, format: :turbo_stream)
      end

      assert_response :unauthorized

      assert_select "div[data-viral--flash-type-value='error']" do
        assert_select 'div', "#{I18n.t('common.statuses.error')}: #{I18n.t('action_policy.unauthorized')}"
      end
    end

    test 'group metadata templates destroy renders error from error_message when not deleted' do
      metadata_template = metadata_templates(:group_one_metadata_template0)
      MetadataTemplates::DestroyService.any_instance.stubs(:execute).returns(nil)
      Groups::MetadataTemplatesController.any_instance.stubs(:error_message)
                                         .returns('Destroy failed from error_message')

      assert_no_difference('MetadataTemplate.count') do
        delete group_metadata_template_path(@group, metadata_template, format: :turbo_stream)
      end

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
