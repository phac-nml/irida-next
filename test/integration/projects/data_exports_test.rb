# frozen_string_literal: true

require 'test_helper'

module Projects
  class DataExportsTest < ActionDispatch::IntegrationTest
    def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @user = users(:john_doe)
      @group1 = groups(:group_one)
      @group5 = groups(:group_five)
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

    test 'can access new linelist data export dialog' do
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

    test 'cannot access new data export dialog without proper permissions' do
      sign_out @user
      sign_in users(:ryan_doe)

      get new_data_export_path(export_type: 'linelist', namespace_id: @project1.namespace.id, ids: [@sample1.id]),
          as: :turbo_stream

      assert_response :unauthorized

      assert_select 'dialog', count: 0
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

    test 'create analysis export using users project shared workflow execution from user we show page' do
      sign_out @user
      user = users(:james_doe)
      sign_in user

      get workflow_execution_path(@shared_workflow_execution1)
      assert_response :success

      assert_select 'h1', text: @shared_workflow_execution1.name || @shared_workflow_execution1.id

      assert_select 'button', text: I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

      get new_data_export_path(export_type: 'analysis', workflow_execution_id: @shared_workflow_execution1.id),
          as: :turbo_stream

      assert_response :success

      export_name = 'test data export'

      assert_difference 'DataExport.count', 1 do
        post data_exports_path(format: :turbo_stream),
             params: {
               data_export: {
                 export_type: 'analysis',
                 name: export_name,
                 email_notification: true,
                 export_parameters: { 'ids' => [@shared_workflow_execution1.id],
                                      'analysis_type' => 'user' }
               }
             }
      end

      follow_redirect!
      assert_response :success

      assert_select 'div:nth-child(2) dd', text: export_name
    end

    test 'create csv linelist export from project samples page' do
      get namespace_project_samples_path(@group1, @project1)
      assert_response :success

      assert_select "input[type='checkbox'][value='#{@sample1.id}']", count: 1

      export_name = 'test csv export'

      params = { 'data_export' => {
                   'export_type' => 'linelist',
                   'name' => export_name,
                   'export_parameters' => {
                     'ids' => [@sample1.id],
                     'namespace_id' => @project1.namespace.id,
                     'linelist_format' => 'csv',
                     'metadata_fields' => %w[metadatafield1 metadatafield2]
                   }
                 },
                 format: :turbo_stream }

      assert_difference('DataExport.count', 1) do
        post data_exports_path, params: params
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'data_exports.create.success', name: export_name
                      )}"
      end

      assert_select 'div:nth-child(2) dd', text: export_name
      assert_select 'div:nth-child(4) dd', text: 'csv'
    end

    test 'create xlsx linelist export from project samples page' do
      get namespace_project_samples_path(@group1, @project1)
      assert_response :success

      assert_select "input[type='checkbox'][value='#{@sample1.id}']", count: 1

      export_name = 'test xlsx export'

      params = { 'data_export' => {
                   'export_type' => 'linelist',
                   'name' => export_name,
                   'export_parameters' => {
                     'ids' => [@sample1.id],
                     'namespace_id' => @project1.namespace.id,
                     'linelist_format' => 'xlsx',
                     'metadata_fields' => %w[metadatafield1 metadatafield2]
                   }
                 },
                 format: :turbo_stream }

      assert_difference('DataExport.count', 1) do
        post data_exports_path, params: params
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'data_exports.create.success', name: export_name
                      )}"
      end

      assert_select 'div:nth-child(2) dd', text: export_name
      assert_select 'div:nth-child(4) dd', text: 'xlsx'
    end

    test 'create analysis export with single workflow execution from project workflow executions index page' do
      get namespace_project_workflow_executions_path(@group1, @project1)
      assert_response :success

      assert_select "input[type='checkbox'][value='#{@workflow_execution4.id}']", count: 1

      get new_data_export_path(export_type: 'analysis', analysis_type: 'project', namespace_id: @project1.namespace.id,
                               ids: [@workflow_execution4.id]),
          as: :turbo_stream

      assert_response :success

      assert_select 'dialog' do
        assert_select 'h1', text: I18n.t('data_exports.new_analysis_export_dialog.title')
      end

      export_name = 'test data export'

      assert_difference 'DataExport.count', 1 do
        post data_exports_path(format: :turbo_stream),
             params: {
               data_export: {
                 export_type: 'analysis',
                 name: export_name,
                 email_notification: true,
                 export_parameters: { 'ids' => [@workflow_execution4.id], 'namespace_id' => @project1.namespace.id,
                                      'analysis_type' => 'project' }
               }
             }
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'data_exports.create.success', name: export_name
                      )}"
      end

      assert_select 'dl', count: 1
      assert_select 'div:nth-child(2) dd', text: export_name
    end

    test 'analysis export with multiple shared workflow executions from project workflow executions index page' do
      sign_out @user
      user = users(:james_doe)
      sign_in user

      get namespace_project_workflow_executions_path(@group5, @project22)
      assert_response :success

      assert_select "input[type='checkbox'][value='#{@shared_workflow_execution1.id}']", count: 1
      assert_select "input[type='checkbox'][value='#{@shared_workflow_execution2.id}']", count: 1

      get new_data_export_path(export_type: 'analysis', analysis_type: 'project', namespace_id: @project22.namespace.id,
                               ids: [@shared_workflow_execution1.id, @shared_workflow_execution2.id]),
          as: :turbo_stream

      assert_response :success

      assert_select 'dialog' do
        assert_select 'h1', text: I18n.t('data_exports.new_analysis_export_dialog.title', locale: user.locale)
      end

      export_name = 'test data export'

      assert_difference 'DataExport.count', 1 do
        post data_exports_path(format: :turbo_stream),
             params: {
               data_export: {
                 export_type: 'analysis',
                 name: export_name,
                 email_notification: true,
                 export_parameters: { 'ids' => [@shared_workflow_execution1.id, @shared_workflow_execution2.id],
                                      'namespace_id' => @project22.namespace.id,
                                      'analysis_type' => 'project' }
               }
             }
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success', locale: user.locale)}: #{I18n.t(
                        'data_exports.create.success', name: export_name, locale: user.locale
                      )}"
      end

      assert_select 'dl', count: 1
      assert_select 'div:nth-child(2) dd', text: export_name
    end

    test 'create analysis export using users shared workflow execution from project workflow execution show page' do
      sign_out @user

      user = users(:james_doe)
      sign_in user

      get namespace_project_workflow_execution_path(@group5, @project22, @shared_workflow_execution1)
      assert_response :success
      export_name = 'test data export'

      assert_select 'button', text: I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

      assert_difference 'DataExport.count', 1 do
        post data_exports_path(format: :turbo_stream),
             params: {
               data_export: {
                 export_type: 'analysis',
                 name: export_name,
                 email_notification: true,
                 export_parameters: { 'ids' => [@shared_workflow_execution1.id],
                                      'namespace_id' => @project22.namespace.id,
                                      'analysis_type' => 'project' }
               }
             }
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success', locale: user.locale)}: #{I18n.t(
                        'data_exports.create.success', name: export_name, locale: user.locale
                      )}"
      end

      assert_select 'dl', count: 1
      assert_select 'div:nth-child(2) dd', text: export_name
    end

    test 'create analysis export from project shared workflow execution from project workflow execution show page' do
      sign_out @user
      user = users(:james_doe)
      sign_in user

      get namespace_project_workflow_execution_path(@group5, @project22, @shared_workflow_execution2)
      assert_response :success

      export_name = 'test data export'

      assert_select 'button', text: I18n.t('workflow_executions.show.create_export_button', locale: user.locale)

      assert_difference 'DataExport.count', 1 do
        post data_exports_path(format: :turbo_stream),
             params: {
               data_export: {
                 export_type: 'analysis',
                 name: export_name,
                 email_notification: true,
                 export_parameters: { 'ids' => [@shared_workflow_execution2.id],
                                      'namespace_id' => @project22.namespace.id,
                                      'analysis_type' => 'project' }
               }
             }
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success', locale: user.locale)}: #{I18n.t(
                        'data_exports.create.success', name: export_name, locale: user.locale
                      )}"
      end

      assert_select 'dl', count: 1
      assert_select 'div:nth-child(2) dd', text: export_name
    end

    test 'clicking links in preview tab for analysis data export from project shared workflow execution' do
      sign_out @user
      sign_in users(:james_doe)

      data_export12 = data_exports(:data_export_twelve)
      we_output = attachments(:workflow_execution_completed_output_attachment)
      swe_output = attachments(:samples_shared_workflow_execution_completed_output_attachment)
      sample47 = samples(:sample47)

      get data_export_path(data_export12, tab: 'preview')

      assert_select 'h2', text: data_export12.file.filename.to_s

      assert_select 'li:first-child span', text: I18n.t('data_exports.preview.manifest_json')
      assert_select 'li:nth-child(2)' do
        assert_select 'a', text: @shared_workflow_execution2.id,
                           href: redirect_data_export_path(data_export12, identifier: @shared_workflow_execution2.id),
                           identifier: @shared_workflow_execution2.id
      end
      assert_select 'li:nth-child(2) ul' do
        assert_select 'li:first-child span', text: we_output.file.filename.to_s
        assert_select 'ul:last-child' do
          assert_select 'li:first-child' do
            assert_select 'a', text: sample47.puid,
                               href: redirect_data_export_path(data_export12, identifier: sample47.puid)
          end
          assert_select 'li:first-child ul' do
            assert_select 'li:first-child span', text: swe_output.file.filename.to_s
          end
        end
      end

      assert_select 'svg.folder-open-icon', count: 2
      assert_select 'svg.file-text-icon', count: 3

      get redirect_data_export_path(data_export12, identifier: @shared_workflow_execution2.id)
      follow_redirect!
      assert_response :success
      assert_select 'h1', text: @shared_workflow_execution2.name || @shared_workflow_execution2.id

      get redirect_data_export_path(data_export12, identifier: sample47.puid)
      follow_redirect!
      assert_response :success

      assert_select 'h1', text: sample47.name
      assert_select 'span', text: sample47.puid
    end

    test 'cannot create analysis export with non-completed workflow execution from project WE index page' do
      get namespace_project_workflow_executions_path(@group1, @project1)
      assert_response :success

      assert_select "input[type='checkbox'][value='#{@workflow_execution4.id}']", count: 1
      assert_select "input[type='checkbox'][value='#{@workflow_execution5.id}']", count: 1

      export_name = 'test data export'

      assert_no_difference 'DataExport.count' do
        post data_exports_path(format: :turbo_stream),
             params: {
               data_export: {
                 export_type: 'analysis',
                 name: export_name,
                 email_notification: true,
                 export_parameters: { 'ids' => [@workflow_execution4.id, @workflow_execution5.id],
                                      'namespace_id' => @project1.namespace.id,
                                      'analysis_type' => 'project' }
               }
             }
      end

      assert_response :unprocessable_entity

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='error']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.error')}: #{I18n.t(
                        'services.data_exports.create.non_completed_workflow_executions'
                      )}"
      end
    end
  end
end
