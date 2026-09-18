# frozen_string_literal: true

require 'test_helper'

class DataExportsTest < ActionDispatch::IntegrationTest
  def setup
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
    project1 = projects(:project1)
    sample1 = samples(:sample1)
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)
    get data_export_path(@data_export1, tab: 'preview')

    assert_select 'h2', text: @data_export1.file.filename.to_s
    assert_select 'li:first-child span', text: I18n.t('data_exports.preview.manifest_json')
    assert_select 'li:nth-child(2) span', text: project1.namespace.puid
    assert_select 'li:nth-child(2) ul' do
      assert_select 'li:first-child span', text: sample1.puid
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
  end

  test 'zip file contents in preview tab for workflow execution data export' do
    we_output = attachments(:workflow_execution_completed_output_attachment)
    swe_output = attachments(:samples_workflow_execution_completed_output_attachment)
    sample46 = samples(:sample46)

    get data_export_path(@data_export7, tab: 'preview')

    assert_select 'h2', text: @data_export7.file.filename.to_s

    assert_select 'li:first-child span', text: I18n.t('data_exports.preview.manifest_json')
    assert_select 'li:nth-child(2) span', text: @workflow_execution1.id
    assert_select 'li:nth-child(2) ul' do
      assert_select 'li:first-child span', text: we_output.file.filename.to_s
      assert_select 'ul:last-child' do
        assert_select 'li:first-child span', text: sample46.puid

        assert_select 'li:first-child ul' do
          assert_select 'li:first-child span', text: swe_output.file.filename.to_s
        end
      end
    end

    assert_select 'svg.folder-open-icon', count: 2
    assert_select 'svg.file-text-icon', count: 3
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
    visit data_exports_path

    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 7, count: 7,
                                                                                    locale: @user.locale))
    assert_selector 'table tbody tr', count: 7

    fill_in placeholder: I18n.t(:'data_exports.index.search.placeholder'),
            with: @data_export1.id
    find('input.t-search-component').send_keys(:return)

    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                    locale: @user.locale))

    within('table tbody') do
      assert_selector ' tr', count: 1
      assert_text @data_export1.id
      assert_text @data_export1.name
    end

    fill_in placeholder: I18n.t(:'data_exports.index.search.placeholder'),
            with: @data_export1.name
    find('input.t-search-component').send_keys(:return)

    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                    locale: @user.locale))

    within('table tbody') do
      assert_selector 'tr', count: 2
      assert_text @data_export1.id
      assert_text @data_export1.name
      assert_text @data_export10.id
      assert_text @data_export10.name
    end

    fill_in placeholder: I18n.t(:'data_exports.index.search.placeholder'),
            with: 'something that does not exist'
    find('input.t-search-component').send_keys(:return)

    within 'section[role="status"]' do
      assert_text I18n.t('components.viral.pagy.empty_state.title')
      assert_text I18n.t('components.viral.pagy.empty_state.description')
    end
  end

  test 'clicking links in preview tab for sample data export' do
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)

    get data_export_path(@data_export1, tab: 'preview')
    assert_response :success

    assert_select 'li:nth-child(2)' do
      assert_select 'a', text: @project1.namespace.puid,
                         href: redirect_data_export_path(@data_export1, identifier: @project1.namespace.puid)
    end

    get redirect_data_export_path(@data_export1, identifier: @project1.namespace.puid)

    follow_redirect!
    assert_response :success

    assert_select 'h1', text: @project1.name

    get data_export_path(@data_export1, tab: 'preview')
    assert_response :success

    assert_select 'li:nth-child(2) ul' do
      assert_select 'li:first-child' do
        assert_select 'a', text: @sample1.puid,
                           href: redirect_data_export_path(@data_export1, identifier: @sample1.puid)
      end
    end

    get redirect_data_export_path(@data_export1, identifier: @sample1.puid)

    follow_redirect!
    assert_response :success

    assert_select 'h1', text: @sample1.name
    assert_select 'span', text: @sample1.puid

    assert_select 'table' do
      assert_select 'tbody' do
        assert_select 'tr', count: 2
        assert_select 'tr:first-child th:first-child', text: attachment2.puid
        assert_select 'tr:first-child td:nth-child(2)', text: attachment2.file.filename.to_s
        assert_select 'tr:nth-child(2) th:first-child', text: attachment1.puid
        assert_select 'tr:nth-child(2) td:nth-child(2)', text: attachment1.file.filename.to_s
      end
    end
  end
end
