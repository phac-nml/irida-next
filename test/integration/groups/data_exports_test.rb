# frozen_string_literal: true

require 'test_helper'

module Groups
  class DataExportsTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:john_doe)
      @group1 = groups(:group_one)
      @group5 = groups(:group_five)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample47 = samples(:sample47)
      @group_shared_workflow_execution1 = workflow_executions(:workflow_execution_completed_group_shared1)
      @group_shared_workflow_execution2 = workflow_executions(:workflow_execution_completed_group_shared2)
      @data_export9 = data_exports(:data_export_nine)

      sign_in @user
    end

    test 'member with access level >= analyst can see create export button on samples pages' do
      get group_samples_url(@group1)

      assert_select 'button', text: I18n.t('shared.samples.actions_dropdown.label')

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export')
    end

    test 'member with access level <= analyst cannot see create export button on samples pages' do
      sign_out @user
      sign_in users(:ryan_doe)
      get group_samples_url(@group1)

      assert_select 'button', text: I18n.t('shared.samples.actions_dropdown.label'), count: 0

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export'), count: 0

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export'), count: 0
    end

    test 'can access new data export dialog' do
      get group_samples_url(@group1)
      assert_response :success

      assert_select 'button', text: I18n.t('shared.samples.actions_dropdown.label')

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

      assert_select "form[action^='#{new_data_export_path}']" do
        assert_select "input[type='hidden'][name='export_type'][value='linelist']", count: 1
      end

      get new_data_export_path(export_type: 'linelist', namespace_id: @group1.id, ids: [@sample1.id]),
          as: :turbo_stream
      assert_response :success

      assert_select 'dialog' do
        assert_select 'h1', text: I18n.t('data_exports.new_linelist_export_dialog.title')
        assert_select 'button',
                      text: I18n.t('data_exports.new.samples_count.non_zero').gsub!('COUNT_PLACEHOLDER', '0')
        assert_select 'h2', text: I18n.t('data_exports.new_linelist_export_dialog.metadata')
        assert_select 'p', text: I18n.t('data_exports.new_linelist_export_dialog.fields_instructions')
        assert_select 'p', text: I18n.t('data_exports.new_linelist_export_dialog.available_list_title')
        assert_select 'p', text: I18n.t('data_exports.new_linelist_export_dialog.selected_list_title')

        assert_select 'ul#available-list' do
          assert_select 'li > span', text: 'metadatafield1'

          assert_select 'li > span', text: 'metadatafield2'
        end

        assert_select 'ul#selected-list' do
          assert_select 'li', count: 0
        end

        assert_select 'button[aria-disabled="true"]',
                      text: I18n.t('common.actions.remove')
        assert_select 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.add')
        assert_select 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.up')
        assert_select 'button[aria-disabled="true"]',
                      text: I18n.t('components.sortable_lists.v1.list_component.down')

        assert_select "form[action=\"#{data_exports_path}\"][method=\"post\"]" do
          assert_select 'label', text: "#{I18n.t('data_exports.new_linelist_export_dialog.format')} *"
          assert_select 'input[type="radio"][value="csv"]'
          assert_select 'input[type="radio"][value="xlsx"]'

          assert_select 'label', text: I18n.t('data_exports.new.name_label')
          assert_select 'input[name="data_export[name]"]'
          assert_select 'label', text: I18n.t('data_exports.new.email_label')
          assert_select 'input[name="data_export[email_notification]"]'
        end
      end
    end

    test 'can create data export from group samples page' do
      get new_data_export_path(export_type: 'linelist', namespace_id: @group1.id, ids: [@sample1.id]),
          as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: I18n.t('data_exports.new_linelist_export_dialog.title')

      # csv export
      params = { 'data_export' => {
                   'export_type' => 'linelist',
                   'name' => 'test data export csv',
                   'export_parameters' => { 'ids' => [@sample1.id], 'linelist_format' => 'csv',
                                            'namespace_id' => @group1.id }
                 },
                 format: :turbo_stream }

      assert_difference('DataExport.count', 1) do
        post data_exports_path, params: params
      end

      follow_redirect!
      assert_response :success

      assert_select 'div:nth-child(2) dd', text: 'test data export csv'

      get new_data_export_path(export_type: 'linelist', namespace_id: @group1.id, ids: [@sample1.id]),
          as: :turbo_stream
      assert_response :success

      # xlsx export
      params = { 'data_export' => {
                   'export_type' => 'linelist',
                   'name' => 'test data export xlsx',
                   'export_parameters' => { 'ids' => [@sample1.id], 'linelist_format' => 'xlsx',
                                            'namespace_id' => @group1.id }
                 },
                 format: :turbo_stream }

      assert_difference('DataExport.count', 1) do
        post data_exports_path, params: params
      end

      follow_redirect!
      assert_response :success

      assert_select 'div:nth-child(2) dd', text: 'test data export xlsx'
    end
  end
end
