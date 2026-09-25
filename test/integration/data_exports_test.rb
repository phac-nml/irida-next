# frozen_string_literal: true

require 'test_helper'

class DataExportsTest < ActionDispatch::IntegrationTest
  def setup # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @user = users(:john_doe)
    @group1 = groups(:group_one)
    @project1 = projects(:project1)
    @data_export1 = data_exports(:data_export_one)
    @data_export2 = data_exports(:data_export_two)
    @data_export6 = data_exports(:data_export_six)
    @data_export7 = data_exports(:data_export_seven)
    @data_export8 = data_exports(:data_export_eight)
    @data_export9 = data_exports(:data_export_nine)
    @data_export10 = data_exports(:data_export_ten)
    @sample1 = samples(:sample1)
    @workflow_execution1 = workflow_executions(:irida_next_example_completed_with_output)
    @workflow_execution2 = workflow_executions(:irida_next_example_completed)
    @workflow_execution3 = workflow_executions(:irida_next_example_error)
    @shared_workflow_execution2 = workflow_executions(:workflow_execution_completed_shared2)

    sign_in @user
  end

  test 'can view data exports' do
    freeze_time
    get data_exports_path

    assert_response :success

    assert_select 'tbody' do
      assert_select 'tr', count: 7
      assert_select "tr[id='#{dom_id(@data_export1)}'] td:first-child", text: @data_export1.id
      assert_select "tr[id='#{dom_id(@data_export1)}'] td:nth-child(2)", text: @data_export1.name

      assert_select "tr[id='#{dom_id(@data_export1)}'] td:nth-child(3)",
                    text: I18n.t(:"data_exports.types.#{@data_export1.export_type}")
      assert_select "tr[id='#{dom_id(@data_export1)}'] td:nth-child(4)",
                    text: I18n.t(:"common.statuses.#{@data_export1.status}").upcase
      assert_select "tr[id='#{dom_id(@data_export1)}'] td:nth-child(6)",
                    text: I18n.l(@data_export1.expires_at.localtime.to_date, format: :long)

      assert_select "tr[id='#{dom_id(@data_export2)}'] td:first-child", text: @data_export2.id
      assert_select "tr[id='#{dom_id(@data_export2)}'] td:nth-child(2)", text: /\A\s*\z/
      assert_select "tr[id='#{dom_id(@data_export2)}'] td:nth-child(3)",
                    text: I18n.t(:"data_exports.types.#{@data_export2.export_type}")
      assert_select "tr[id='#{dom_id(@data_export2)}'] td:nth-child(4)",
                    text: I18n.t(:"common.statuses.#{@data_export2.status}").upcase
      assert_select "tr[id='#{dom_id(@data_export2)}'] td:nth-child(6)", text: /\A\s*\z/

      assert_select "tr[id='#{dom_id(@data_export6)}'] td:first-child", text: @data_export6.id
      assert_select "tr[id='#{dom_id(@data_export6)}'] td:nth-child(2)", text: @data_export6.name
      assert_select "tr[id='#{dom_id(@data_export6)}'] td:nth-child(3)",
                    text: I18n.t(:"data_exports.types.#{@data_export6.export_type}")
      assert_select "tr[id='#{dom_id(@data_export6)}'] td:nth-child(4)",
                    text: I18n.t(:"common.statuses.#{@data_export6.status}").upcase
      assert_select "tr[id='#{dom_id(@data_export6)}'] td:nth-child(6)", text: /\A\s*\z/

      assert_select "tr[id='#{dom_id(@data_export7)}'] td:first-child", text: @data_export7.id
      assert_select "tr[id='#{dom_id(@data_export7)}'] td:nth-child(2)", text: @data_export7.name
      assert_select "tr[id='#{dom_id(@data_export7)}'] td:nth-child(3)",
                    text: I18n.t(:"data_exports.types.#{@data_export7.export_type}")
      assert_select "tr[id='#{dom_id(@data_export7)}'] td:nth-child(4)",
                    text: I18n.t(:"common.statuses.#{@data_export7.status}").upcase
      assert_select "tr[id='#{dom_id(@data_export7)}'] td:nth-child(6)",
                    text: I18n.l(@data_export7.expires_at.localtime.to_date, format: :long)
    end
  end

  test 'data exports with status ready will have download in action dropdown' do
    get data_exports_path
    assert_response :success

    assert_select 'table' do
      assert_select 'tbody' do
        assert_select "tr[id='#{dom_id(@data_export6)}']" do
          assert_select 'td:nth-child(4)', text: I18n.t(:'common.statuses.processing').upcase
          assert_select 'td:last-child', text: /#{I18n.t('common.actions.download')}/, count: 0
          assert_select 'td:last-child', text: I18n.t('common.actions.delete')
        end
        assert_select "tr[id='#{dom_id(@data_export1)}']" do
          assert_select 'td:nth-child(4)', text: I18n.t(:'common.statuses.ready').upcase
          assert_select 'td:last-child', text: /#{I18n.t('common.actions.download')}/
          assert_select 'td:last-child', text: /#{I18n.t('common.actions.delete')}/
        end
      end
    end
  end

  test 'can delete data exports on listing page' do
    get data_exports_path
    assert_response :success

    assert_select 'h1', text: I18n.t('data_exports.index.title')

    assert_select 'table' do
      assert_select 'tbody' do
        assert_select 'tr', count: 7 do
          assert_select "tr[id='#{dom_id(@data_export1)}']" do
            assert_select 'td:nth-child(4)', text: I18n.t(:'common.statuses.ready').upcase
            assert_select 'td:last-child', text: /#{I18n.t('common.actions.delete')}/
          end
        end
      end
    end

    assert_difference -> { DataExport.count }, -1 do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{ I18n.t(
                      :'data_exports.destroy.success',
                      name: @data_export1.name
                    )}"
    end
  end

  test 'can delete data export from data export details page' do
    get data_export_path(@data_export2)

    assert_select 'button', text: I18n.t('common.actions.remove')

    assert_difference -> { DataExport.count }, -1 do
      delete data_export_path(@data_export2),
             as: :turbo_stream
    end

    follow_redirect!
    assert_response :success

    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{ I18n.t(
                      :'data_exports.destroy.success',
                      name: @data_export2.id
                    )}"
    end

    assert_select 'table' do
      assert_select 'tbody' do
        assert_select "tr[id='#{dom_id(@data_export2)}'] td:first-child", count: 0
      end
    end
  end

  test 'empty state is shown when there are no data exports' do
    sign_out @user
    sign_in users(:micha_doe)
    get data_exports_path
    assert_response :success

    data_export = data_exports(:data_export_eleven)

    assert_select 'table' do
      assert_select 'tbody' do
        assert_select 'tr', count: 1 do
          assert_select "tr[id='#{dom_id(data_export)}']" do
            assert_select 'td:nth-child(4)', text: I18n.t(:'common.statuses.ready').upcase
            assert_select 'td:last-child', text: /#{I18n.t('common.actions.delete')}/
          end
        end
      end
    end

    assert_difference -> { DataExport.count }, -1 do
      delete data_export_path(data_export),
             as: :turbo_stream
    end
    follow_redirect!
    assert_response :success

    assert_select 'section[role="status"]' do
      assert_select 'h2', text: I18n.t('data_exports.index.no_data_exports')
      assert_select 'div > span', text: I18n.t('data_exports.index.no_data_exports_message')
    end
  end

  test 'can view data export details page' do
    get data_export_path(@data_export1)
    assert_response :success

    assert_select 'h1', text: @data_export1.name

    assert_select 'button',
                  text: I18n.t('common.actions.download')

    assert_select 'button#preview-tab',
                  text: I18n.t('data_exports.show.tabs.preview'), count: 1

    assert_select 'div:first-child dd', text: @data_export1.id
    assert_select 'div:nth-child(2) dd', text: @data_export1.name
    assert_select 'div:nth-child(3) dd', text: I18n.t(:"data_exports.types.#{@data_export1.export_type}")

    assert_select 'div:nth-child(4)' do
      assert_select 'dt', text: I18n.t('data_exports.summary.status')
      assert_select 'dd' do
        assert_select 'span.bg-green-100.text-green-800.text-xs.font-medium.rounded-full',
                      text: I18n.t(:"common.statuses.#{@data_export1.status}").upcase
      end
    end

    assert_select 'div:nth-child(5) dd',
                  text: I18n.l(@data_export1.created_at.localtime.to_date, format: :long)
    assert_select 'div:last-child dd',
                  text: I18n.l(@data_export1.expires_at.localtime.to_date, format: :long)

    get data_export_path(@data_export2)
    assert_response :success

    assert_select 'button',
                  text: I18n.t('common.actions.download')

    assert_select 'button#preview-tab',
                  text: I18n.t('data_exports.show.tabs.preview'), count: 0

    # name not displayed if data_export.name is nil
    assert_select 'dt', text: I18n.t('common.labels.name'), count: 0

    # Available once export is ready text is displayed if the export is still processing
    assert_select 'div:nth-child(3)' do
      assert_select 'dt', text: I18n.t('data_exports.summary.status')
      assert_select 'dd' do
        assert_select 'span.bg-slate-100.text-slate-800.text-xs.font-medium.rounded-full',
                      text: I18n.t(:"common.statuses.#{@data_export2.status}").upcase
      end
    end

    assert_select 'div:last-child dd',
                  text: I18n.t('data_exports.summary.once_ready')

    get data_export_path(@data_export7)

    assert_select 'div:first-child dd', text: @data_export7.id
    assert_select 'div:nth-child(2) dd', text: @data_export7.name
    assert_select 'div:nth-child(3) dd',
                  text: I18n.t(:"data_exports.types.#{@data_export7.export_type}")
    assert_select 'div:nth-child(4) dd', text: I18n.t(:"common.statuses.#{@data_export7.status}").upcase
    assert_select 'div:nth-child(5) dd',
                  text: I18n.l(@data_export7.created_at.localtime.to_date, format: :long)
    assert_select 'div:last-child dd',
                  text: I18n.l(@data_export7.expires_at.localtime.to_date, format: :long)
  end

  test 'zip file contents in preview tab for sample data export' do
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)
    get data_export_path(@data_export1, tab: 'preview')

    assert_select 'h2', text: @data_export1.file.filename.to_s
    assert_select 'li:first-child span', text: I18n.t('data_exports.preview.manifest_json')
    assert_select 'li:nth-child(2)' do
      assert_select 'a', text: @project1.namespace.puid,
                         href: redirect_data_export_path(@data_export1, identifier: @project1.namespace.puid)
    end
    assert_select 'li:nth-child(2) ul' do
      assert_select 'li:first-child' do
        assert_select 'a', text: @sample1.puid,
                           href: redirect_data_export_path(@data_export1, identifier: @sample1.puid)
      end
      assert_select 'li:first-child ul' do
        assert_select 'li:first-child span', text: attachment1.puid
        assert_select 'li:first-child ul' do
          assert_select 'li:first-child span', text: attachment1.file.filename.to_s
        end
      end
      assert_select 'li:last-child ul' do
        assert_select 'li:first-child span', text: attachment2.puid
        assert_select 'li:first-child ul' do
          assert_select 'li:first-child span', text: attachment2.file.filename.to_s
        end
      end
    end

    assert_select 'svg.folder-open-icon', count: 3
    assert_select 'svg.file-text-icon', count: 4

    get redirect_data_export_path(@data_export1, identifier: @project1.namespace.puid)
    follow_redirect!
    assert_response :success
    assert_select 'h1', text: @project1.name

    get redirect_data_export_path(@data_export1, identifier: @sample1.puid)
    follow_redirect!
    assert_response :success

    assert_select 'h1', text: @sample1.name
    assert_select 'span', text: @sample1.puid
  end

  test 'zip file contents in preview tab for workflow execution data export' do
    we_output = attachments(:workflow_execution_completed_output_attachment)
    swe_output = attachments(:samples_workflow_execution_completed_output_attachment)
    sample46 = samples(:sample46)

    get data_export_path(@data_export7, tab: 'preview')

    assert_select 'h2', text: @data_export7.file.filename.to_s

    assert_select 'li:first-child span', text: I18n.t('data_exports.preview.manifest_json')
    assert_select 'li:nth-child(2)' do
      assert_select 'a', text: @workflow_execution1.id,
                         href: redirect_data_export_path(@data_export7),
                         identifier: @workflow_execution1.id
    end
    assert_select 'li:nth-child(2) ul' do
      assert_select 'li:first-child span', text: we_output.file.filename.to_s
      assert_select 'ul:last-child' do
        assert_select 'li:first-child' do
          assert_select 'a', text: sample46.puid,
                             href: redirect_data_export_path(@data_export7, identifier: sample46.puid)
        end
        assert_select 'li:first-child ul' do
          assert_select 'li:first-child span', text: swe_output.file.filename.to_s
        end
      end
    end

    assert_select 'svg.folder-open-icon', count: 2
    assert_select 'svg.file-text-icon', count: 3

    get redirect_data_export_path(@data_export7, identifier: @workflow_execution1.id)
    follow_redirect!
    assert_response :success
    assert_select 'h1', text: @workflow_execution1.name || @workflow_execution1.id

    get redirect_data_export_path(@data_export7, identifier: sample46.puid)
    follow_redirect!
    assert_response :success

    assert_select 'h1', text: sample46.name
    assert_select 'span', text: sample46.puid

    # shared workflow execution preview and redirect tests
    sign_out users(:john_doe)
    login_as users(:micha_doe)
    data_export11 = data_exports(:data_export_eleven)
    sample47 = samples(:sample47)
    swe_output = attachments(:samples_shared_workflow_execution_completed_output_attachment)
    get data_export_path(data_export11, tab: 'preview')
    assert_response :success

    assert_select 'h2', text: data_export11.file.filename.to_s

    assert_select 'li:first-child span', text: I18n.t('data_exports.preview.manifest_json')
    assert_select 'li:nth-child(2)' do
      assert_select 'a', text: @shared_workflow_execution2.id,
                         href: redirect_data_export_path(data_export11, identifier: @shared_workflow_execution2.id),
                         identifier: @shared_workflow_execution2.id
    end
    assert_select 'li:nth-child(2) ul' do
      assert_select 'li:first-child span', text: swe_output.file.filename.to_s
      assert_select 'ul:last-child' do
        assert_select 'li:first-child' do
          assert_select 'a', text: sample47.puid,
                             href: redirect_data_export_path(data_export11, identifier: sample47.puid)
        end
        assert_select 'li:first-child ul' do
          assert_select 'li:first-child span', text: swe_output.file.filename.to_s
        end
      end
    end

    assert_select 'svg.folder-open-icon', count: 2
    assert_select 'svg.file-text-icon', count: 3

    get redirect_data_export_path(data_export11, identifier: @shared_workflow_execution2.id)
    follow_redirect!
    assert_response :success
    assert_select 'h1', text: @shared_workflow_execution2.name || @shared_workflow_execution2.id

    get redirect_data_export_path(data_export11, identifier: sample47.puid)
    follow_redirect!
    assert_response :success

    assert_select 'h1', text: sample47.name
    assert_select 'span', text: sample47.puid
  end

  test 'create export state between completed and non-completed workflow executions' do
    submitted_workflow_execution = workflow_executions(:irida_next_example_submitted)
    get workflow_execution_path(submitted_workflow_execution)
    assert_response :success

    assert_select 'button[disabled]', text: I18n.t('workflow_executions.show.create_export_button')

    get workflow_execution_path(@workflow_execution1)
    assert_response :success

    assert_select 'button[disabled]', text: I18n.t('workflow_executions.show.create_export_button'), count: 0
  end

  test 'linelist export with ready status does not have preview tab' do
    get data_export_path(@data_export9)
    assert_response :success

    assert_select 'div:nth-child(4) dd', text: 'xlsx'

    assert_select 'button', text: I18n.t('data_exports.show.tabs.summary')
    assert_select 'button', text: I18n.t('data_exports.show.tabs.preview'), count: 0
  end

  test 'can filter by id or name' do
    get data_exports_path
    assert_response :success

    assert_select 'table tbody tr', count: 7

    get data_exports_path, params: { q: { id_or_name_cont: @data_export1.id } }
    assert_response :success

    assert_select 'table tbody tr', count: 1
    assert_select "tr[id='#{dom_id(@data_export1)}']" do
      assert_select 'td', text: @data_export1.id
      assert_select 'td', text: @data_export1.name
    end

    get data_exports_path, params: { q: { id_or_name_cont: @data_export1.name } }
    assert_response :success

    assert_select 'table tbody tr', count: 2
    assert_select "tr[id='#{dom_id(@data_export1)}']"
    assert_select "tr[id='#{dom_id(@data_export10)}']"

    get data_exports_path, params: { q: { id_or_name_cont: 'something that does not exist' } }
    assert_response :success

    assert_select 'section[role="status"]' do
      assert_select 'h2', text: I18n.t('components.viral.pagy.empty_state.title')
      assert_select 'div > span', text: I18n.t('components.viral.pagy.empty_state.description')
    end
  end

  test 'create analysis export with completed workflow executions from user workflow executions index page' do
    get workflow_executions_path
    assert_response :success

    assert_select "input[type='checkbox'][value='#{@workflow_execution1.id}']", count: 1
    assert_select "input[type='checkbox'][value='#{@workflow_execution2.id}']", count: 1

    get new_data_export_path(export_type: 'analysis', ids: [@workflow_execution1.id, @workflow_execution2.id]),
        as: :turbo_stream

    assert_response :success

    export_name = 'test data export'

    assert_difference 'DataExport.count', 1 do
      post data_exports_path(format: :turbo_stream),
           params: {
             data_export: {
               export_type: 'analysis',
               name: export_name,
               export_parameters: { 'ids' => [@workflow_execution1.id, @workflow_execution2.id],
                                    'analysis_type' => 'user' }
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

  test 'cannot create analysis export with non-completed workflow executions from user WE index page' do
    get workflow_executions_path
    assert_response :success

    export_name = 'test data export'

    assert_no_difference 'DataExport.count' do
      post data_exports_path(format: :turbo_stream),
           params: {
             data_export: {
               export_type: 'analysis',
               name: export_name,
               export_parameters: { 'ids' => [@workflow_execution1.id, @workflow_execution3.id],
                                    'analysis_type' => 'user' }
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

  test 'renders sample, linelist, and single workflow analysis export dialogs' do
    get new_data_export_path(export_type: 'sample', namespace_id: @project1.namespace.id,
                             ids: [@sample1.id]), as: :turbo_stream
    assert_response :success

    get new_data_export_path(export_type: 'linelist', namespace_id: @project1.namespace.id,
                             ids: [@sample1.id]), as: :turbo_stream
    assert_response :success

    get new_data_export_path(export_type: 'analysis', single_workflow: true,
                             workflow_execution_id: @workflow_execution1.id), as: :turbo_stream
    assert_response :success
  end

  test 'supports explicit data export sorting' do
    get data_exports_path, params: { q: { s: 'id asc' } }

    assert_response :success
  end

  test 'renders an error when destroying a data export fails' do
    DataExports::DestroyService.any_instance.stubs(:execute)

    delete data_export_path(@data_export1), as: :turbo_stream

    assert_response :unprocessable_content
    assert_select "div[role='alert'][aria-live='assertive']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.error')}: #{I18n.t(
                      'data_exports.destroy.error', name: @data_export1.name
                    )}"
    end
  end

  test 'renders an error when an export exceeds the size limit' do
    max_gigabytes = Irida::CurrentSettings.max_data_export_size_gigabytes
    DataExport.any_instance.stubs(:source_size_bytes).returns(max_gigabytes.gigabytes)

    post data_exports_path(format: :turbo_stream),
         params: {
           data_export: {
             export_type: 'sample',
             export_parameters: {
               ids: [@sample1.id],
               namespace_id: @project1.namespace.id,
               attachment_formats: Attachment::FORMAT_REGEX.keys
             }
           }
         }

    assert_response :unprocessable_content
    assert_includes @response.body, 'data-export-dialog-errors'
    assert_includes @response.body,
                    I18n.t('services.data_exports.create.max_data_export_size_exceeded',
                           max_size_gigabytes: max_gigabytes)
  end
end
