# frozen_string_literal: true

require 'application_system_test_case'

class DataExportsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    @data_export1 = data_exports(:data_export_one)
    @data_export2 = data_exports(:data_export_two)
    @data_export6 = data_exports(:data_export_six)
    @data_export7 = data_exports(:data_export_seven)
    @data_export9 = data_exports(:data_export_nine)
    @group1 = groups(:group_one)
    @project1 = projects(:project1)
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @sample30 = samples(:sample30)
    @workflow_execution = workflow_executions(:irida_next_example_completed_with_output)
    login_as @user
  end

  test 'can view data exports' do
    freeze_time
    visit data_exports_path

    within('tbody') do
      assert_selector 'tr', count: 7
      assert_selector 'tr:first-child td:first-child ', text: @data_export1.id
      assert_selector 'tr:first-child td:nth-child(2)', text: @data_export1.name

      assert_selector 'tr:first-child td:nth-child(3)', text: I18n.t(:"data_exports.types.#{@data_export1.export_type}")
      assert_selector 'tr:first-child td:nth-child(4)', text: I18n.t(:"data_exports.status.#{@data_export1.status}")
      assert_selector 'tr:first-child td:nth-child(6)',
                      text: I18n.l(@data_export1.expires_at.localtime, format: :full_date)

      assert_selector 'tr:nth-child(2) td:first-child', text: @data_export2.id
      assert find('tr:nth-child(2) td:nth-child(2)').text.blank?
      assert_selector 'tr:nth-child(2) td:nth-child(3)',
                      text: I18n.t(:"data_exports.types.#{@data_export2.export_type}")
      assert_selector 'tr:nth-child(2) td:nth-child(4)', text: I18n.t(:"data_exports.status.#{@data_export2.status}")
      assert find('tr:nth-child(2) td:nth-child(6)').text.blank?

      assert_selector 'tr:nth-child(3) td:first-child', text: @data_export6.id
      assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @data_export6.name
      assert_selector 'tr:nth-child(3) td:nth-child(3)',
                      text: I18n.t(:"data_exports.types.#{@data_export6.export_type}")
      assert_selector 'tr:nth-child(3) td:nth-child(4)', text: I18n.t(:"data_exports.status.#{@data_export6.status}")
      assert find('tr:nth-child(3) td:nth-child(6)').text.blank?

      assert_selector 'tr:nth-child(4) td:first-child', text: @data_export7.id
      assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @data_export7.name
      assert_selector 'tr:nth-child(4) td:nth-child(3)',
                      text: I18n.t(:"data_exports.types.#{@data_export7.export_type}")
      assert_selector 'tr:nth-child(4) td:nth-child(4)', text: I18n.t(:"data_exports.status.#{@data_export7.status}")
      assert_selector 'tr:nth-child(4) td:nth-child(6)',
                      text: I18n.l(@data_export7.expires_at.localtime, format: :full_date)
    end
  end

  test 'data exports with status ready will have download in action dropdown' do
    visit data_exports_path

    within('tbody') do
      within %(tr:nth-child(2) td:last-child) do
        assert_text I18n.t('data_exports.index.actions.delete')
      end

      within %(tr:first-child td:last-child) do
        assert_text I18n.t('data_exports.index.actions.download')
        assert_text I18n.t('data_exports.index.actions.delete')
      end
    end
  end

  test 'can delete data exports on listing page' do
    visit data_exports_path

    assert_selector 'table tbody tr', count: 7
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'table tbody tr', count: 6
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'table tbody tr', count: 5
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'table tbody tr', count: 4
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'table tbody tr', count: 3
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'table tbody tr', count: 2
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'table tbody tr', count: 1
    within('tbody') do
      click_link I18n.t('data_exports.index.actions.delete'), match: :first
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

    within('tbody') do
      within %(tr:first-child td:first-child) do
        click_link @data_export1.id
      end
    end

    assert_selector 'div:first-child dd', text: @data_export1.id
    assert_selector 'div:nth-child(2) dd', text: @data_export1.name
    assert_selector 'div:nth-child(3) dd', text: I18n.t(:"data_exports.types.#{@data_export1.export_type}")
    assert_selector 'div:nth-child(4) dd', text: I18n.t(:"data_exports.status.#{@data_export1.status}")
    assert_selector 'div:nth-child(5) dd',
                    text: I18n.l(@data_export1.created_at.localtime, format: :full_date)
    assert_selector 'div:last-child dd',
                    text: I18n.l(@data_export1.expires_at.localtime, format: :full_date)
  end

  test 'name is not shown on data export page if data_export.name is nil' do
    visit data_export_path(@data_export2)

    assert_no_text I18n.t('data_exports.summary.name')
  end

  test 'expire has once_ready text on data export page if data_export.status is processing' do
    visit data_export_path(@data_export2)

    assert_selector 'div:last-child dd',
                    text: I18n.t('data_exports.summary.once_ready')
  end

  test 'data export status pill colors' do
    # processing
    visit data_export_path(@data_export2)

    within %(div:nth-child(3) dd) do
      assert_selector 'span.bg-slate-100.text-slate-800.text-xs.font-medium.rounded-full',
                      text: I18n.t(:"data_exports.status.#{@data_export2.status}")
    end

    # ready
    visit data_export_path(@data_export1)

    within %(div:nth-child(4) dd) do
      assert_selector 'span.bg-green-100.text-green-800.text-xs.font-medium.rounded-full',
                      text: I18n.t(:"data_exports.status.#{@data_export1.status}")
    end
  end

  test 'hidden preview tab and disabled download btn when status is processing' do
    visit data_export_path(@data_export1)

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t(:'data_exports.show.download')
    assert_text I18n.t(:'data_exports.show.tabs.preview')

    visit data_export_path(@data_export2)

    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t(:'data_exports.show.download')
    assert_no_text I18n.t(:'data_exports.show.tabs.preview')
  end

  test 'can remove export from export page' do
    visit data_exports_path

    within('tbody') do
      assert_selector 'tr', count: 7
      assert_text @data_export2.id
    end

    visit data_export_path(@data_export2)

    click_link I18n.t(:'data_exports.show.remove_button')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within('tbody') do
      assert_selector 'tr', count: 6
      assert_no_text @data_export2.id
    end
  end

  test 'member with access level >= analyst can see create export button on samples pages' do
    # project samples page
    visit namespace_project_samples_url(@group1, @project1)
    assert_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label'), count: 1

    # group samples page
    visit group_samples_url(@group1)
    assert_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label'), count: 1
  end

  test 'user with access level == guest cannot see create export button on sample pages' do
    login_as users(:ryan_doe)

    # project samples page
    visit namespace_project_samples_url(@group1, @project1)
    assert_no_selector 'a', text: I18n.t('projects.samples.index.create_export_button')

    # group samples page
    visit group_samples_url(@group1)
    assert_no_selector 'a', text: I18n.t('projects.samples.index.create_export_button'), count: 1
  end

  test 'create export from project samples page' do
    visit data_exports_path
    within('tbody') do
      assert_selector 'tr', count: 7
      assert_no_text 'test data export'
    end
    # project samples page
    visit namespace_project_samples_url(@group1, @project1)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')
    assert_accessible
    click_link I18n.t('projects.samples.index.create_export_button.sample_export'), match: :first

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.sample_description.singular')
      )
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample1.name
        assert_text @sample1.puid
      end
      assert_text I18n.t('data_exports.new_sample_export_dialog.select_formats')
      assert_text I18n.t('data_exports.new_sample_export_dialog.format_description',
                         selected: I18n.t('data_exports.new_sample_export_dialog.selected').downcase)
      within("##{I18n.t('data_exports.new_sample_export_dialog.available')}") do
        assert_no_selector 'li'
      end
      within("##{I18n.t('data_exports.new_sample_export_dialog.selected')}") do
        assert_selector 'li', count: 9
        Attachment::FORMAT_REGEX.each_key do |format|
          assert_text format
        end
      end
      assert_text I18n.t('data_exports.new_sample_export_dialog.name_label')
      assert_text I18n.t('data_exports.new_sample_export_dialog.email_label')

      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new_sample_export_dialog.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create export from group samples page' do
    visit data_exports_path
    within('tbody') do
      assert_selector 'tr', count: 7
      assert_no_text 'test data export'
    end
    # project samples page
    visit group_samples_url(@group1)
    assert_text '1-20 of 26'
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
      find("input[type='checkbox'][value='#{@sample2.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.sample_export'), match: :first

    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '2'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.sample_description.plural')
      ).gsub! 'COUNT_PLACEHOLDER', '2'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample1.name
        assert_text @sample1.puid
        assert_text @sample2.name
        assert_text @sample2.puid
      end
      assert_text I18n.t('data_exports.new_sample_export_dialog.select_formats')
      assert_text I18n.t('data_exports.new_sample_export_dialog.format_description',
                         selected: I18n.t('data_exports.new_sample_export_dialog.selected').downcase)
      within("##{I18n.t('data_exports.new_sample_export_dialog.available')}") do
        assert_no_selector 'li'
      end
      within("##{I18n.t('data_exports.new_sample_export_dialog.selected')}") do
        assert_selector 'li', count: 9
        Attachment::FORMAT_REGEX.each_key do |format|
          assert_text format
        end
      end
      assert_text I18n.t('data_exports.new_sample_export_dialog.name_label')
      assert_text I18n.t('data_exports.new_sample_export_dialog.email_label')

      fill_in I18n.t('data_exports.new_sample_export_dialog.name_label'), with: 'test data export'
      check I18n.t('data_exports.new_sample_export_dialog.email_label')
      click_button I18n.t('data_exports.new_sample_export_dialog.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'checking off samples on different page does not affect current page\'s export samples' do
    subgroup12a = groups(:subgroup_twelve_a)
    project29 = projects(:project29)
    sample32 = samples(:sample32)

    visit namespace_project_samples_url(subgroup12a, project29)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample32.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')

    visit namespace_project_samples_url(@group1, @project1)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')

    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.sample_export'), match: :first
    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample1.name
        assert_text @sample1.puid
      end
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.sample_description.singular')
      )
    end
  end

  test 'zip file contents in preview tab for sample data export' do
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)
    visit data_export_path(@data_export1, tab: 'preview')

    assert_text @data_export1.file.filename.to_s
    assert_text I18n.t('data_exports.preview.manifest_json')
    assert_text @project1.namespace.puid
    assert_text @sample1.puid
    assert_text attachment1.puid
    assert_text attachment2.puid
    assert_text attachment1.file.filename.to_s
    assert_text attachment2.file.filename.to_s

    assert_selector 'svg.Viral-Icon__Svg.icon-folder_open', count: 4
    assert_selector 'svg.Viral-Icon__Svg.icon-document_text', count: 3
  end

  test 'clicking links in preview tab for data export' do
    attachment1 = attachments(:attachment1)
    attachment2 = attachments(:attachment2)
    visit data_export_path(@data_export1, tab: 'preview')

    click_link @project1.namespace.puid

    assert_current_path(namespace_project_samples_path(@project1.parent, @project1))
    assert_selector 'h1', text: I18n.t(:'projects.samples.index.title')

    visit data_export_path(@data_export1, tab: 'preview')

    click_link @sample1.puid

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
    visit workflow_execution_path(@workflow_execution)

    click_link I18n.t('workflow_executions.show.create_export_button'), match: :first
    within 'dialog[open].dialog--size-lg' do
      assert_no_selector "turbo-frame[id='list_selections']"
      assert_text I18n.t('data_exports.new_analysis_export_dialog.name_label')
      assert_text I18n.t('data_exports.new_analysis_export_dialog.email_label')
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new_analysis_export_dialog.description.analysis_html',
               id: @workflow_execution.id)
      )
      find('input#data_export_name').fill_in with: 'test data export'
      find("input[type='checkbox'][id='data_export_email_notification']").click
      click_button I18n.t('data_exports.new_analysis_export_dialog.submit_button')
    end

    assert_selector 'dl', count: 1
    assert_selector 'div:nth-child(2) dd', text: 'test data export'
  end

  test 'create export state between completed and non-completed workflow executions' do
    submitted_workflow_execution = workflow_executions(:irida_next_example_submitted)
    visit workflow_execution_path(submitted_workflow_execution)

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    visit workflow_execution_path(@workflow_execution)
    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
  end

  test 'data export type analysis on summary tab' do
    visit data_export_path(@data_export7, tab: 'summary')

    assert_selector 'div:first-child dd', text: @data_export7.id
    assert_selector 'div:nth-child(2) dd', text: @data_export7.name
    assert_selector 'div:nth-child(3) dd', text: I18n.t(:"data_exports.types.#{@data_export7.export_type}")
    assert_selector 'div:nth-child(4) dd', text: I18n.t(:"data_exports.status.#{@data_export7.status}")
    assert_selector 'div:nth-child(5) dd',
                    text: I18n.l(@data_export7.created_at.localtime, format: :full_date)
    assert_selector 'div:last-child dd',
                    text: I18n.l(@data_export7.expires_at.localtime, format: :full_date)
  end

  test 'zip file contents in preview tab for workflow execution data export' do
    we_output = attachments(:workflow_execution_completed_output_attachment)
    swe_output = attachments(:samples_workflow_execution_completed_output_attachment)
    sample46 = samples(:sample46)
    visit data_export_path(@data_export7, tab: 'preview')

    assert_text @data_export7.file.filename.to_s
    assert_text I18n.t('data_exports.preview.manifest_json')

    assert_text we_output.file.filename.to_s
    assert_text swe_output.file.filename.to_s
    assert_text sample46.puid

    assert_selector 'svg.Viral-Icon__Svg.icon-folder_open', count: 1
    assert_selector 'svg.Viral-Icon__Svg.icon-document_text', count: 3
  end

  test 'projects with samples containing no metadata should have linelist export link disabled' do
    project = projects(:project2)
    sample3 = samples(:sample3)

    visit namespace_project_samples_url(@group1, project)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample3.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.linelist_export')
  end

  test 'groups with samples containing no metadata should have linelist export link disabled' do
    group = groups(:group_sixteen)
    sample43 = samples(:sample43)

    visit group_samples_url(group)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{sample43.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.linelist_export')
  end

  test 'new linelist export dialog' do
    visit namespace_project_samples_url(@group1, @project1)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample30.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      assert_accessible
      assert_text I18n.t('data_exports.new_linelist_export_dialog.title')
      assert_text I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text I18n.t('data_exports.new_linelist_export_dialog.metadata')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.metadata_description',
                         available: I18n.t('data_exports.new_linelist_export_dialog.available').downcase,
                         selected: I18n.t('data_exports.new_linelist_export_dialog.selected').downcase)
      assert_text I18n.t('data_exports.new_linelist_export_dialog.available')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.selected')
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.remove_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.add_all')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.format')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.csv')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.xlsx')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.name_label')
      assert_text I18n.t('data_exports.new_linelist_export_dialog.email_label')

      assert_no_selector 'turbo-frame[id="list_selections"]'
      assert_no_text @sample30.name
      assert_no_text @sample30.puid
      assert_no_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.sample_description.singular')
      )

      click_button I18n.t('data_exports.new.samples_count.non_zero').gsub! 'COUNT_PLACEHOLDER', '1'
      assert_text ActionController::Base.helpers.strip_tags(
        I18n.t('data_exports.new.sample_description.singular')
      )
      assert_selector 'turbo-frame[id="list_selections"]'
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample30.name
        assert_text @sample30.puid
      end

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.available')}']" do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.selected')}']" do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end
    end
  end

  test 'add all and remove all buttons in new linelist export dialog' do
    visit namespace_project_samples_url(@group1, @project1)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample30.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.available')}']" do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.selected')}']" do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end

      assert_selector 'input[disabled]'
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.remove_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.add_all')

      click_button I18n.t('viral.sortable_lists_component.add_all')

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.selected')}']" do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.available')}']" do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end

      assert_no_selector 'input[disabled]'
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.add_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.remove_all')

      click_button I18n.t('viral.sortable_lists_component.remove_all')

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.available')}']" do
        assert_text 'metadatafield1'
        assert_text 'metadatafield2'
        assert_selector 'li', count: 2
      end

      within "ul[id='#{I18n.t('data_exports.new_linelist_export_dialog.selected')}']" do
        assert_no_text 'metadatafield1'
        assert_no_text 'metadatafield2'
        assert_no_selector 'li'
      end

      assert_selector 'input[disabled]'
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.remove_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.add_all')
    end
  end

  test 'create csv export from project samples page' do
    visit namespace_project_samples_url(@group1, @project1)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within('tbody') do
      find("input[type='checkbox'][value='#{@sample30.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('viral.sortable_lists_component.add_all')
      find('input#data_export_name').fill_in with: 'test csv export'
      click_button I18n.t('data_exports.new_linelist_export_dialog.submit_button')
    end

    within('dl') do
      assert_selector 'div:nth-child(2) dd', text: 'test csv export'
      assert_selector 'div:nth-child(4) dd', text: 'csv'
    end
  end

  test 'create xlsx export from group samples page' do
    visit group_samples_url(@group1)
    assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t('projects.samples.index.create_export_button.label')

    within('tbody') do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    assert_no_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t('projects.samples.index.create_export_button.label')
    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.linelist_export')

    within 'dialog[open].dialog--size-lg' do
      click_button I18n.t('viral.sortable_lists_component.add_all')
      find('input#data_export_name').fill_in with: 'test xlsx export'
      find('input#xlsx-format').click
      click_button I18n.t('data_exports.new_linelist_export_dialog.submit_button')
    end

    within('dl') do
      assert_selector 'div:nth-child(2) dd', text: 'test xlsx export'
      assert_selector 'div:nth-child(4) dd', text: 'xlsx'
    end
  end

  test 'linelist export with ready status does not have preview tab' do
    visit data_export_path(@data_export9)

    assert_selector 'div:nth-child(4) dd', text: 'xlsx'

    assert_text I18n.t('data_exports.show.tabs.summary')
    assert_no_text I18n.t('data_exports.show.tabs.preview')
  end

  test 'add all, remove all and submit buttons in new_sample_export_dialog' do
    visit namespace_project_samples_url(@group1, @project1)

    within %(#samples-table) do
      find("input[type='checkbox'][value='#{@sample1.id}']").click
    end

    click_button I18n.t('projects.samples.index.create_export_button.label')
    click_link I18n.t('projects.samples.index.create_export_button.sample_export'), match: :first

    within 'dialog[open].dialog--size-lg' do
      within("##{I18n.t('data_exports.new_sample_export_dialog.available')}") do
        assert_no_selector 'li'
      end
      within("##{I18n.t('data_exports.new_sample_export_dialog.selected')}") do
        assert_selector 'li', count: 9
        Attachment::FORMAT_REGEX.each_key do |format|
          assert_text format
        end
      end

      assert_no_selector 'input[disabled]'
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.add_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.remove_all')

      click_button I18n.t('viral.sortable_lists_component.remove_all')

      within("##{I18n.t('data_exports.new_sample_export_dialog.selected')}") do
        assert_no_selector 'li'
      end
      within("##{I18n.t('data_exports.new_sample_export_dialog.available')}") do
        assert_selector 'li', count: 9
        Attachment::FORMAT_REGEX.each_key do |format|
          assert_text format
        end
      end

      assert_selector 'input[disabled]'
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.remove_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.add_all')

      click_button I18n.t('viral.sortable_lists_component.add_all')

      within("##{I18n.t('data_exports.new_sample_export_dialog.available')}") do
        assert_no_selector 'li'
      end
      within("##{I18n.t('data_exports.new_sample_export_dialog.selected')}") do
        assert_selector 'li', count: 9
        Attachment::FORMAT_REGEX.each_key do |format|
          assert_text format
        end
      end

      assert_no_selector 'input[disabled]'
      assert_selector 'button.pointer-events-none.cursor-not-allowed',
                      text: I18n.t('viral.sortable_lists_component.add_all')
      assert_no_selector 'button.pointer-events-none.cursor-not-allowed',
                         text: I18n.t('viral.sortable_lists_component.remove_all')
    end
  end
end
