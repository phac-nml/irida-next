# frozen_string_literal: true

require 'test_helper'

module Projects
  class DataExportsTest < ActionDispatch::IntegrationTest
    def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @user = users(:john_doe)
      @group1 = groups(:group_one)
      @project1 = projects(:project1)
      @project22 = projects(:project22)
      @sample1 = samples(:sample1)
      @sample30 = samples(:sample30)
      @sample47 = samples(:sample47)
      @workflow_execution1 = workflow_executions(:irida_next_example_completed_with_output)
      @workflow_execution2 = workflow_executions(:irida_next_example_completed)
      @workflow_execution3 = workflow_executions(:irida_next_example_error)
      @workflow_execution4 = workflow_executions(:automated_workflow_execution)
      @workflow_execution5 = workflow_executions(:automated_example_error)
      @shared_workflow_execution1 = workflow_executions(:workflow_execution_completed_shared1)
      @shared_workflow_execution2 = workflow_executions(:workflow_execution_completed_shared2)
      @data_export1 = data_exports(:data_export_one)
      @data_export2 = data_exports(:data_export_two)
      @data_export8 = data_exports(:data_export_eight)
      @data_export10 = data_exports(:data_export_ten)

      sign_in @user
    end

    test 'member with access level >= analyst can see create export button on samples pages' do
      get namespace_project_samples_url(@group1, @project1)

      assert_select 'button', text: I18n.t('shared.samples.actions_dropdown.label')

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export')
    end

    test 'member with access level <= analyst cannot see create export button on samples pages' do
      sign_out @user
      sign_in users(:ryan_doe)
      get namespace_project_samples_url(@group1, @project1)

      assert_select 'button', text: I18n.t('shared.samples.actions_dropdown.label'), count: 0

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export'), count: 0

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.sample_export'), count: 0
    end

    test 'can access new data export dialog' do
      get namespace_project_samples_url(@group1, @project1)
      assert_response :success

      assert_select 'button', text: I18n.t('shared.samples.actions_dropdown.label')

      assert_select 'ul > li[role="none"] > button',
                    text: I18n.t('shared.samples.actions_dropdown.linelist_export')

      assert_select "form[action^='#{new_data_export_path}']" do
        assert_select "input[type='hidden'][name='export_type'][value='linelist']", count: 1
      end

      get new_data_export_path(export_type: 'linelist', namespace_id: @project1.namespace.id, ids: [@sample1.id]),
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
          assert_select 'li:first-child' do
            assert_select 'span', text: 'metadatafield1'
          end
          assert_select 'li:nth-child(2)' do
            assert_select 'span', text: 'metadatafield2'
          end
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

    test 'can create data export from project samples page' do
      get new_data_export_path(export_type: 'linelist', namespace_id: @project1.namespace.id, ids: [@sample1.id]),
          as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: I18n.t('data_exports.new_linelist_export_dialog.title')

      params = { 'data_export' => {
                   'export_type' => 'linelist',
                   'name' => 'test data export csv',
                   'export_parameters' => { 'ids' => [@sample1.id], 'linelist_format' => 'csv',
                                            'namespace_id' => @project1.namespace.id }
                 },
                 format: :turbo_stream }

      assert_difference('DataExport.count', 1) do
        post data_exports_path, params: params
      end

      follow_redirect!
      assert_response :success

      assert_select 'div:nth-child(2) dd', text: 'test data export csv'

      get new_data_export_path(export_type: 'linelist', namespace_id: @project1.namespace.id, ids: [@sample1.id]),
          as: :turbo_stream
      assert_response :success

      params = { 'data_export' => {
                   'export_type' => 'linelist',
                   'name' => 'test data export xlsx',
                   'export_parameters' => { 'ids' => [@sample1.id], 'linelist_format' => 'xlsx',
                                            'namespace_id' => @project1.namespace.id }
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
