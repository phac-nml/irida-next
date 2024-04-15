# frozen_string_literal: true

require 'application_system_test_case'

class DataExportsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    @data_export1 = data_exports(:data_export_one)
    @data_export2 = data_exports(:data_export_two)
    @data_export6 = data_exports(:data_export_six)
    @namespace = groups(:group_one)
    @project = projects(:project1)
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
    login_as @user
  end

  test 'can view data exports' do
    freeze_time
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_selector 'tr:first-child td:first-child ', text: @data_export1.id
      assert_selector 'tr:first-child td:nth-child(2)', text: @data_export1.name
      assert_selector 'tr:first-child td:nth-child(3)', text: @data_export1.export_type.capitalize
      assert_selector 'tr:first-child td:nth-child(4)', text: @data_export1.status.capitalize
      assert_selector 'tr:first-child td:nth-child(6)',
                      text: I18n.l(@data_export1.expires_at.localtime, format: :full_date)

      assert_selector 'tr:nth-child(2) td:first-child', text: @data_export2.id
      assert find('tr:nth-child(2) td:nth-child(2)').text.blank?
      assert_selector 'tr:nth-child(2) td:nth-child(3)', text: @data_export2.export_type.capitalize
      assert_selector 'tr:nth-child(2) td:nth-child(4)', text: @data_export2.status.capitalize
      assert find('tr:nth-child(2) td:nth-child(6)').text.blank?

      assert_selector 'tr:nth-child(3) td:first-child', text: @data_export6.id
      assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @data_export6.name
      assert_selector 'tr:nth-child(3) td:nth-child(3)', text: @data_export6.export_type.capitalize
      assert_selector 'tr:nth-child(3) td:nth-child(4)', text: @data_export6.status.capitalize
      assert find('tr:nth-child(3) td:nth-child(6)').text.blank?
    end
  end

  test 'data exports with status ready will have download in action dropdown' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:nth-child(2) td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_no_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
      end

      within %(tr:first-child td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
      end
    end
  end

  test 'can delete data exports on listing page' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      first('button.Viral-Dropdown--icon').click
      within('div[data-viral--dropdown-target="menu"] ul') do
        click_link I18n.t('data_exports.index.actions.delete'), match: :first
      end
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 2
      first('button.Viral-Dropdown--icon').click
      within('div[data-viral--dropdown-target="menu"] ul') do
        click_link I18n.t('data_exports.index.actions.delete'), match: :first
      end
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 1
      first('button.Viral-Dropdown--icon').click
      within('div[data-viral--dropdown-target="menu"] ul') do
        click_link I18n.t('data_exports.index.actions.delete'), match: :first
      end
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_no_selector 'table'
    assert_text I18n.t('data_exports.index.no_data_exports')
    assert_text I18n.t('data_exports.index.no_data_exports_message')
  end

  test 'can navigate to individual data export page from data exports page' do
    freeze_time
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:first-child td:first-child) do
        click_link @data_export1.id
      end
    end

    within %(#data-export-listing) do
      assert_selector 'div:first-child dd', text: @data_export1.id
      assert_selector 'div:nth-child(2) dd', text: @data_export1.name
      assert_selector 'div:nth-child(3) dd', text: @data_export1.export_type.capitalize
      assert_selector 'div:nth-child(4) dd', text: @data_export1.status.capitalize
      assert_selector 'div:nth-child(5) dd',
                      text: I18n.l(@data_export1.created_at.localtime, format: :full_date)
      assert_selector 'div:last-child dd',
                      text: I18n.l(@data_export1.expires_at.localtime, format: :full_date)
    end
  end

  test 'name is not shown on data export page if data_export.name is nil' do
    visit data_export_path(@data_export2)

    within %(#data-export-listing) do
      assert_no_text I18n.t('data_exports.summary.name')
    end
  end

  test 'expire has once_ready text on data export page if data_export.status is processing' do
    visit data_export_path(@data_export2)

    within %(#data-export-listing) do
      assert_selector 'div:last-child dd',
                      text: I18n.t('data_exports.summary.once_ready')
    end
  end

  test 'data export status pill colors' do
    # processing
    visit data_export_path(@data_export2)

    within %(#data-export-listing) do
      within %(div:nth-child(3) dd) do
        assert_selector 'span.bg-gray-100.text-gray-800.text-xs.font-medium.rounded-full',
                        text: @data_export2.status.capitalize
      end
    end

    # ready
    visit data_export_path(@data_export1)

    within %(#data-export-listing) do
      within %(div:nth-child(4) dd) do
        assert_selector 'span.bg-green-100.text-green-800.text-xs.font-medium.rounded-full',
                        text: @data_export1.status.capitalize
      end
    end
  end

  test 'hidden preview tab and disabled download btn when status is processing' do
    visit data_export_path(@data_export1)

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t(:'data_exports.show.download')
    assert_text I18n.t(:'data_exports.show.tabs.preview')

    visit data_export_path(@data_export2)

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t(:'data_exports.show.download')
    assert_no_text I18n.t(:'data_exports.show.tabs.preview')
  end

  test 'can remove export from export page' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_text @data_export2.id
    end

    visit data_export_path(@data_export2)

    click_link I18n.t(:'data_exports.show.remove_button')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 2
      assert_no_text @data_export2.id
    end
  end

  test 'member with access level >= analyst can see create export button on samples pages' do
    login_as users(:john_doe)

    # project samples page
    visit namespace_project_samples_url(@namespace, @project)
    assert_selector 'a', text: I18n.t('projects.samples.index.create_export_button'), count: 1

    # group samples page
    visit group_samples_url(@namespace)
    assert_selector 'a', text: I18n.t('projects.samples.index.create_export_button'), count: 1
  end

  test 'user with access level == guest cannot see create export button on sample pages' do
    login_as users(:ryan_doe)

    # project samples page
    visit namespace_project_samples_url(@namespace, @project)
    assert_no_selector 'a', text: I18n.t('projects.samples.index.create_export_button')

    # group samples page
    visit group_samples_url(@namespace)
    assert_no_selector 'a', text: I18n.t('projects.samples.index.create_export_button'), count: 1
  end

  test 'create export from project samples page' do
    login_as users(:john_doe)

    visit data_exports_path
    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_no_text 'test data export'
    end
    # project samples page
    visit namespace_project_samples_url(@namespace, @project)
    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button')

    click_link I18n.t('projects.samples.index.create_export_button'), match: :first
    within 'dialog[open].dialog--size-lg' do
      assert_text I18n.t('data_exports.new_export_dialog.name_label')
      assert_text I18n.t('data_exports.new_export_dialog.email_label')
      assert_text I18n.t('data_exports.new_export_dialog.summary.start.start.singular')

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new_export_dialog.submit_button')
    end

    within %(#data-export-listing) do
      assert_selector 'dl', count: 1
      assert_selector 'div:nth-child(2) dd', text: 'test data export'
    end
  end

  test 'create export from group samples page' do
    login_as users(:john_doe)

    visit data_exports_path
    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_no_text 'test data export'
    end
    # project samples page
    visit group_samples_url(@namespace)
    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
      find("input[type='checkbox'][value='#{@sample2.id}']").click
    end

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button')

    click_link I18n.t('projects.samples.index.create_export_button'), match: :first
    within 'dialog[open].dialog--size-lg' do
      assert_text I18n.t('data_exports.new_export_dialog.name_label')
      assert_text I18n.t('data_exports.new_export_dialog.email_label')
      assert_text I18n.t('data_exports.new_export_dialog.summary.sample.start.plural').gsub! 'COUNT_PLACEHOLDER', '2'

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new_export_dialog.submit_button')
    end

    within %(#data-export-listing) do
      assert_selector 'dl', count: 1
      assert_selector 'div:nth-child(2) dd', text: 'test data export'
    end
  end

  test 'checking off samples on different page does not affect current page\'s export samples' do
    login_as users(:john_doe)
    subgroup12a = groups(:subgroup_twelve_a)
    project29 = projects(:project29)
    sample32 = samples(:sample32)

    visit namespace_project_samples_url(subgroup12a, project29)
    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample32.id}']").click
    end

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button')

    visit namespace_project_samples_url(@namespace, @project)
    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button')

    click_link I18n.t('projects.samples.index.create_export_button'), match: :first
    within 'dialog[open].dialog--size-lg' do
      assert_text I18n.t('data_exports.new_export_dialog.summary.start.singular')
    end
  end

  test 'zip file contents in preview tab for sample data export' do
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)
    visit data_export_path(@data_export1, tab: 'preview')

    within %(#data-export-listing) do
      assert_text @data_export1.file.filename.to_s
      assert_text I18n.t('data_exports.preview.manifest_json')
      assert_text @project.namespace.puid
      assert_text @sample1.puid
      assert_text attachment1.puid
      assert_text attachment2.puid
      assert_text attachment1.file.filename.to_s
      assert_text attachment2.file.filename.to_s

      assert_selector 'svg.Viral-Icon__Svg.icon-folder_open', count: 4
      assert_selector 'svg.Viral-Icon__Svg.icon-document_text', count: 3
    end
  end

  test 'clicking links in preview tab for data export' do
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)
    visit data_export_path(@data_export1, tab: 'preview')

    within %(#data-export-listing) do
      click_link @project.namespace.puid
    end

    assert_text @project.namespace.puid
    assert_text @project.name

    visit data_export_path(@data_export1, tab: 'preview')

    within %(#data-export-listing) do
      click_link @sample1.puid
    end

    assert_text @sample1.name
    assert_text @sample1.puid
    within %(#attachments-table-body) do
      assert_selector 'tr', count: 2
      assert_selector 'tr:first-child td:nth-child(2) ', text: attachment1.puid
      assert_selector 'tr:first-child td:nth-child(3) ', text: attachment1.file.filename.to_s
      assert_selector 'tr:nth-child(2) td:nth-child(2)', text: attachment2.puid
      assert_selector 'tr:nth-child(2) td:nth-child(3)', text: attachment2.file.filename.to_s
    end
  end

  test 'create analysis export' do
    login_as users(:john_doe)
    visit workflow_execution_path(@workflow_execution)

    click_link I18n.t('workflow_executions.show.create_export_button'), match: :first
    within 'dialog[open].dialog--size-lg' do
      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new_export_dialog.submit_button')
    end

    within %(#data-export-listing) do
      assert_selector 'dl', count: 1
      assert_selector 'div:nth-child(2) dd', text: 'test data export'
    end
  end

  test 'create export state between completed and non-completed workflow executions' do
    login_as users(:john_doe)
    submitted_workflow_execution = workflow_executions(:irida_next_example_submitted)
    visit workflow_execution_path(submitted_workflow_execution)

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button')

    visit workflow_execution_path(@workflow_execution)
    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button')
  end

  test 'data export type analysis on summary tab' do
    visit data_export_path(@data_export6, tab: 'summary')

    within %(#data-export-listing) do
      assert_selector 'div:nth-child(3) dd', text: @data_export6.export_type.capitalize
    end
  end

  test 'zip file contents in preview tab for workflow execution data export' do
    we_output = attachments(:workflow_execution_completed_output_attachment)
    swe_output = attachments(:samples_workflow_execution_completed_output_attachment)
    sample45 = samples(:sample45)
    visit data_export_path(@data_export6, tab: 'preview')

    within %(#data-export-listing) do
      assert_text @data_export6.file.filename.to_s
      assert_text I18n.t('data_exports.preview.manifest_json')

      assert_text we_output.file.filename.to_s
      assert_text swe_output.file.filename.to_s
      assert_text sample45.puid

      assert_selector 'svg.Viral-Icon__Svg.icon-folder_open', count: 1
      assert_selector 'svg.Viral-Icon__Svg.icon-document_text', count: 3
    end
  end
end
