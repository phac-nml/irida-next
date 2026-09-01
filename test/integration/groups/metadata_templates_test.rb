# frozen_string_literal: true

require 'test_helper'

module Groups
  class MetadataTemplatesTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
      @metadata_template = metadata_templates(:valid_group_metadata_template)
      @sorted_group = groups(:group_two)
      @metadata_template1 = metadata_templates(:group_two_metadata_template1)
      @metadata_template2 = metadata_templates(:group_two_metadata_template2)
    end

    ####################################################################################################################
    # Controller Tests
    ####################################################################################################################

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

    test 'should apply default sort and support metadata template sorting' do
      get group_metadata_templates_path(@sorted_group)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@metadata_template1.name, @metadata_template2.name)

      get group_metadata_templates_path(@sorted_group, params: { q: { s: 'name desc' } })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(@metadata_template2.name, @metadata_template1.name)

      get group_metadata_templates_path(@sorted_group, params: { q: { s: 'created_by_email asc' } })
      assert_response :success
      assert_sort_state(3, 'ascending')
      assert_first_rows_include(@metadata_template1.name, @metadata_template2.name)

      get group_metadata_templates_path(@sorted_group, params: { q: { s: 'created_by_email desc' } })
      assert_response :success
      assert_sort_state(3, 'descending')
      assert_first_rows_include(@metadata_template2.name, @metadata_template1.name)
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

    ####################################################################################################################
    # System Tests
    ####################################################################################################################

    test 'should display metadata templates associated with the group' do
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

    test 'should not display metadata templates listing table if no metadata templates associated with the group' do
      group = groups(:group_five)
      get group_metadata_templates_path(group)
      assert_response :success
      assert_select 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_select 'p', text: I18n.t('groups.metadata_templates.index.subtitle')
      assert_select 'table', count: 0
      assert_select "div[class='empty_state_message']", count: 1
      assert_select "div[class='empty_state_message']",
                    text: /#{Regexp.escape(I18n.t('metadata_templates.table.empty.title',
                                                  namespace_type: group.type.downcase))}/
      assert_select "div[class='empty_state_message']",
                    text: /#{Regexp.escape(I18n.t('metadata_templates.table.empty.description',
                                                  namespace_type: group.type.downcase))}/
    end

    test 'should destroy metadata template associated with the group' do
      metadata_template = metadata_templates(:group_one_metadata_template0)

      assert_difference('MetadataTemplate.count', -1) do
        delete group_metadata_template_path(@group, metadata_template, format: :turbo_stream)
      end
      assert_response :success
      assert_select "div[data-controller='viral--flash']", count: 1
      assert_select "div[data-controller='viral--flash']",
                    text: /#{Regexp.escape(I18n.t(
                                             'concerns.metadata_template_actions.destroy.success',
                                             template_name: metadata_template.name
                                           ))}/
    end

    test 'maintainer or higher can access the metadata template page and create new template' do
      get group_metadata_templates_path(@group)
      assert_response :success
      assert_select 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_select 'p', text: I18n.t('groups.metadata_templates.index.subtitle')
      assert_select 'button', text: I18n.t('groups.metadata_templates.index.new_button'), count: 1

      # Get the new template page
      get new_group_metadata_template_path(@group, format: :turbo_stream)
      assert_response :success
      assert_select 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')

      # Create a new metadata template
      template_params = { metadata_template: { name: 'Group Template011', fields: @group.metadata_fields } }
      assert_difference('MetadataTemplate.count', 1) do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params
      end
      assert_response :success

      # Verify the template was created by fetching the index page again
      get group_metadata_templates_path(@group)
      assert_response :success
      assert_select 'table tbody tr td:nth-child(1)', text: 'Group Template011'
      assert_select 'button', text: I18n.t('groups.metadata_templates.index.new_button'), focused: true
    end

    test 'cannot create a template with no fields selected' do
      template_params = { metadata_template: { name: 'Newest template' } }
      assert_no_difference('MetadataTemplate.count') do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params
      end
      assert_response :unprocessable_content
      assert_select 'p', I18n.t('general.form.error_notification')
      assert_select 'li', I18n.t('errors.format', attribute: I18n.t('activerecord.attributes.metadata_template.fields'),
                                                  message: I18n.t('errors.messages.blank'))
    end

    test 'cannot create a template with no template name entered' do
      template_params = { metadata_template: { fields: @group.metadata_fields } }
      assert_no_difference('MetadataTemplate.count') do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params
      end
      assert_response :unprocessable_content
      assert_select 'p', I18n.t('general.form.error_notification')
      assert_select 'li', I18n.t('errors.format', attribute: I18n.t('activerecord.attributes.metadata_template.name'),
                                                  message: I18n.t('errors.messages.blank'))
    end

    test 'cannot create a template with duplicate fields with same ordering in another template' do
      existing_metadata_template = metadata_templates(:valid_group_metadata_template)
      template_params = { metadata_template: { name: 'New Group Template', fields: existing_metadata_template.fields } }
      assert_no_difference('MetadataTemplate.count') do
        post group_metadata_templates_path(@group, format: :turbo_stream), params: template_params
      end
      assert_response :unprocessable_content
      assert_select 'p', I18n.t('general.form.error_notification')
      assert_select 'li', I18n.t('errors.format',
                                 attribute: I18n.t('activerecord.attributes.metadata_template.fields'),
                                 message: I18n.t('activerecord.errors.models.metadata_template.attributes.fields.taken')) # rubocop:disable Layout/LineLength
    end

    test 'cannot view the add new template button if no fields are available for the group' do
      group = groups(:group_two)
      get group_metadata_templates_path(group)
      assert_response :success
      assert_select 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_select 'p', text: I18n.t('groups.metadata_templates.index.subtitle')
      assert_select 'a', text: I18n.t('groups.metadata_templates.index.new_button'), count: 0
    end

    test 'should edit metadata template associated with the group' do
      metadata_template = metadata_templates(:group_one_metadata_template0)
      unselected_fields = @group.metadata_fields.reject { |field| metadata_template.fields.include? field }
      new_name = 'Group Template011'
      template_params = { metadata_template: { name: new_name, fields: unselected_fields } }
      put group_metadata_template_path(@group, metadata_template, format: :turbo_stream), params: template_params
      assert_response :success
      assert_select "div[data-controller='viral--flash']", count: 1
      assert_select "div[data-controller='viral--flash']",
                    text: /#{Regexp.escape(I18n.t(
                                             'concerns.metadata_template_actions.update.success',
                                             template_name: metadata_template.name
                                           ))}/

      # Verify the template was updated by fetching the index page
      get group_metadata_templates_path(@group)
      assert_response :success
      assert_select 'table tbody tr td:nth-child(1)', text: new_name, focused: true
    end
  end
end
