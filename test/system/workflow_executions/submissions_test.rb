# frozen_string_literal: true

require 'application_system_test_case'

module WorkflowExecutions
  class SubmissionsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    setup do
      @sample22 = samples(:sample22)
      @sample43 = samples(:sample43)
      @project2 = projects(:project2)
      @project = projects(:project37)
      @group1 = groups(:group_one)
      @namespace = groups(:group_sixteen)

      @user = users(:jeff_doe)
      login_as @user
      @jeff_doe_namespace = namespaces_user_namespaces(:jeff_doe_namespace)
      @project_a = projects(:projectA)
      @sample_a = samples(:sampleA)
      @sample_b = samples(:sampleB)
      @attachment_c = attachments(:attachmentC)
      @attachment_fwd2 = attachments(:attachmentPEFWD2)
      @attachment_rev2 = attachments(:attachmentPEREV2)
      @attachment_fwd3 = attachments(:attachmentPEFWD3)
      @attachment_rev3 = attachments(:attachmentPEREV3)
    end

    # used by test 'chunked samples request' to create thousands of samples to test chunked retrieval
    def ensure_project_has_samples!(project, count:) # rubocop:disable Metrics/MethodLength
      return if Sample.where(project_id: project.id).count == count

      Sample.with_deleted.where(project_id: project.id).delete_all

      base_time = Time.utc(2026, 1, 1, 0, 0, 0)
      rows = (1..count).map do |n|
        time = base_time + n.seconds
        {
          name: "Chunked Project Sample #{n}",
          description: "Chunked Project Sample #{n} description.",
          project_id: project.id,
          puid: Irida::PersistentUniqueId.generate(object_class: Sample, time: time),
          created_at: time,
          updated_at: time
        }
      end

      Sample.insert_all!(rows) # rubocop:disable Rails/SkipsModelValidations
      Project.reset_counters(project.id, :samples)
    end

    test 'should display a pipeline selection modal for project samples as owner' do
      user = users(:john_doe)
      login_as user

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.update_samples')
      assert_text I18n.t(:'components.nextflow.email_notification')
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}")
    end

    test 'pipeline selection marks workflow versions outside configured minimum sample limits unavailable' do
      user = users(:john_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      check "checkbox_sample_#{@sample43.id}"
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_selector 'button[data-workflow-selection-workflowversion-param="1.0.3"][aria-disabled="true"]'
      assert_selector 'button[data-workflow-selection-workflowversion-param="1.0.2"][aria-disabled="false"]'
      assert_text I18n.t('shared.workflow_executions.sample_limits.min_samples_required', min_samples: 2)

      find('button[data-workflow-selection-workflowversion-param="1.0.2"]').click

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
    end

    test 'pipeline selection marks workflow versions outside configured maximum sample limits unavailable' do
      user = users(:john_doe)
      login_as user

      visit namespace_project_samples_url(@group1, @project2)

      click_button I18n.t('common.controls.select_all')
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_selector 'button[data-workflow-selection-workflowversion-param="1.0.3"][aria-disabled="true"]'
      assert_selector 'button[data-workflow-selection-workflowversion-param="1.0.2"][aria-disabled="false"]'
      assert_text I18n.t('shared.workflow_executions.sample_limits.max_samples_exceeded', max_samples: 2)
    end

    test 'should display a pipeline selection modal for project samples as maintainer' do
      user = users(:joan_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr', locale: user.locale)

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title',
                                                       locale: user.locale)
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample', locale: user.locale)
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.update_samples', locale: user.locale)
      assert_text I18n.t(:'components.nextflow.email_notification', locale: user.locale)
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}", locale: user.locale)
    end

    test 'should display a pipeline selection modal for project samples as analyst' do
      user = users(:james_doe)
      login_as user

      visit namespace_project_samples_url(namespace_id: @namespace.path, project_id: @project.path)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: user.locale))

      check "checkbox_sample_#{@sample43.id}"
      check "checkbox_sample_#{@sample44.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr', locale: user.locale)

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title',
                                                       locale: user.locale)
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample', locale: user.locale)
      assert_selector 'table[data-test-selector="samplesheet-table"]'
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 2
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:first-child th:first-child',
                      text: @sample43.puid
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr:nth-child(2) th:first-child',
                      text: @sample44.puid

      assert_text I18n.t(:'components.nextflow.unauthorized_to_update_samples', locale: user.locale)
      assert_text I18n.t(:'components.nextflow.email_notification', locale: user.locale)
      assert_text I18n.t(:"components.nextflow.shared_with.#{@project.namespace.type.downcase}", locale: user.locale)
    end

    test 'samplesheet attachment selection behavior' do
      attachment_b = attachments(:attachmentB)
      attachment_d = attachments(:attachmentD)
      ### SETUP START ###
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      # select samples
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"

      # click workflow executions btn
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      # select workflow
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      # TEST 1: Verify autoselected attachments
      # verify auto selected attachments
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: @attachment_c.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev3.file.filename.to_s

      # TEST 2: Verify selection of paired end file autopopulates both PE files
      click_link "#{@sample_b.id}_fastq_1_file_link"

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{@attachment_fwd2.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end

      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
      # both attachment fwd and rev3 were replaced with fwd and rev2
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd2.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev2.file.filename.to_s
      assert_no_text @attachment_fwd3.file.filename.to_s
      assert_no_text @attachment_rev3.file.filename.to_s

      # TEST 3: associated attachment autopopulates to no file when selection changes from PE to non-PE
      click_link "#{@sample_b.id}_fastq_1_file_link"

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{attachment_d.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end

      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')

      # fastq_1 field changed to single-end fastq file, fastq_2 autopopulates to no selected file
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: attachment_d.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_no_text @attachment_fwd3.file.filename.to_s
      assert_no_text @attachment_rev3.file.filename.to_s

      # TEST 4: associated attachment does not autopopulate after selecting non-pe attachment
      click_link "#{@sample_a.id}_fastq_1_file_link"

      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{attachment_b.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
    end

    test 'data retained in samplesheet after data and page change' do
      ### SETUP START ###
      user = users(:john_doe)
      login_as user
      rev_attachment = attachments(:sample22AttachmentFastqREV)
      visit namespace_project_samples_url(@group1, @project2)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                                      locale: user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'input[name="sample_ids[]"]:checked', count: 20

      assert_text 'Samples: 20'
      assert_selector 'strong[data-selection-target="selected"]', text: '20'

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector '#dialog'
      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first

      # verify dialog rendered
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_no_selector "a[id='#{@sample22.id}_fastq_2_file_link']"
      # navigate to page 4
      select '4', from: I18n.t('components.nextflow.samplesheet_component.page_selection.aria_label')
      assert_selector 'select[data-action="change->nextflow--v2--samplesheet#pageSelected"]', text: '4'

      # verify attachment to test initially has a selection
      assert_selector "a[id='#{@sample22.id}_fastq_2_file_link']",
                      text: rev_attachment.file.filename.to_s
      click_link "#{@sample22.id}_fastq_2_file_link", text: rev_attachment.file.filename.to_s

      # select 'No file' option
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # verify no file option exists in non-required field
        assert_selector '#attachment_id_no_attachment'
        find('#attachment_id_no_attachment').click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # file selection is now no file selected
      assert_selector "a[id='#{@sample22.id}_fastq_2_file_link']",
                      text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      # previously selected file no longer exists in table
      assert_no_text rev_attachment.file.filename.to_s
      # change page
      click_button I18n.t('components.nextflow.samplesheet_component.previous')
      assert_selector 'select[data-action="change->nextflow--v2--samplesheet#pageSelected"]', text: '3'
      assert_no_selector "a[id='#{@sample22.id}_fastq_2_file_link']"

      # navigate back to original page
      click_button I18n.t('components.nextflow.samplesheet_component.next')
      assert_selector 'select[data-action="change->nextflow--v2--samplesheet#pageSelected"]', text: '4'
      # verify attachment selection is still 'No file' and original attachment does not exist in table
      assert_selector "a[id='#{@sample22.id}_fastq_2_file_link']",
                      text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_no_text rev_attachment.file.filename.to_s
      ### VERIFY END ###
    end

    test 'samplesheet metadata selection changes samplesheet values and retained after workflow submission' do
      ### SETUP START ###
      user = users(:john_doe)
      namespace = groups(:group_twelve)
      sample33 = samples(:sample33)
      sample34 = samples(:sample34)
      sample35 = samples(:sample35)
      # required mlst.json file for gasclustering submission
      sample33.attachments.create!(
        file: Rails.root.join('test/fixtures/files/s.mlst.json')
      )
      sample34.attachments.create!(
        file: Rails.root.join('test/fixtures/files/s.mlst.json')
      )
      sample35.attachments.create!(
        file: Rails.root.join('test/fixtures/files/s.mlst.json')
      )
      login_as user

      visit group_samples_url(namespace)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: user.locale))
      # select samples
      check "checkbox_sample_#{sample33.id}"
      check "checkbox_sample_#{sample34.id}"
      check "checkbox_sample_#{sample35.id}"

      assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      assert_selector 'strong[data-selection-target="selected"]', text: 3

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/gasclustering'
      click_button 'phac-nml/gasclustering'
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      assert_selector 'h1', text: 'phac-nml/gasclustering'
      find('input#workflow_execution_name').fill_in with: 'test-workflow'

      # check default metadata dropdown selected values
      assert_selector '#field-metadata_1', text: 'metadata_1'
      assert_selector '#field-metadata_2', text: 'metadata_2'

      assert_selector "td[id='#{sample33.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample34.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample35.id}_metadata_1'] input[type='text']", text: ''
      assert_selector "td[id='#{sample33.id}_metadata_2'] input[type='text']", text: ''
      assert_selector "td[id='#{sample34.id}_metadata_2'] input[type='text']", text: ''
      assert_selector "td[id='#{sample35.id}_metadata_2'] input[type='text']", text: ''

      # change metadata_1 and metadata_2 option selection
      select 'metadatafield1', from: 'metadata_1'

      find('input#samplesheet-filter').fill_in with: sample34.name
      find('input#samplesheet-filter').send_keys :enter

      # assert table is filtered to display sample34 only and previous metadata selection is retained
      assert_selector 'table[data-test-selector="samplesheet-table"] tbody tr', count: 1
      assert_selector "td[id='#{sample34.id}_metadata_1'] span", text: sample34.metadata['metadatafield1']

      # select metadata field and verify sample34's respective metadata value is loaded in
      select 'metadatafield2', from: 'metadata_2'
      assert_selector '#field-metadata_2', text: 'metadatafield2'
      assert_selector "td[id='#{sample34.id}_metadata_2'] span", text: sample34.metadata['metadatafield2']

      # undo filter and verify other samples' metadata is loaded and retained
      find('input#samplesheet-filter').fill_in with: ''
      find('input#samplesheet-filter').send_keys :enter
      # check new metadata dropdown selected values
      assert_selector '#field-metadata_1', text: 'metadatafield1'
      assert_selector '#field-metadata_2', text: 'metadatafield2'

      # check metadata values of samples
      assert_selector "td[id='#{sample33.id}_metadata_1'] span", text: sample33.metadata['metadatafield1']
      assert_selector "td[id='#{sample34.id}_metadata_1'] span", text: sample34.metadata['metadatafield1']
      # sample contains no metadata value for this field, stays as text input
      assert_selector "td[id='#{sample35.id}_metadata_1'] input[type='text']", text: ''

      assert_selector "td[id='#{sample33.id}_metadata_2'] span", text: sample33.metadata['metadatafield2']
      assert_selector "td[id='#{sample34.id}_metadata_2'] span", text: sample34.metadata['metadatafield2']
      # sample contains no metadata value for this field, stays as text input
      assert_selector "td[id='#{sample35.id}_metadata_2'] input[type='text']", text: ''

      # submit pipeline
      click_button I18n.t(:'workflow_executions.submissions.create.submit')

      # verify redirection to workflow executions page
      assert_selector 'h1', text: I18n.t(:'shared.workflow_executions.index.title')

      # click the submitted workflow execution from above
      find('table tbody tr:first-child th:first-child a').click

      # verify show page
      assert_selector 'h1', text: 'test-workflow'

      assert_text I18n.t(:'workflow_executions.show.tabs.params')
      # click parameters tab
      click_button I18n.t(:'workflow_executions.show.tabs.params')

      # verify new parameter values
      assert_selector '.metadata_1_header-param input[disabled][value="metadatafield1"]'
      assert_no_selector '.metadata_1_header-param input[disabled][value="metadata_1"]'

      assert_selector '.metadata_2_header-param input[disabled][value="metadatafield2"]'
      assert_no_selector '.metadata_2_header-param input[disabled][value="metadata_2"]'

      # verify samplesheet values
      click_button I18n.t(:'workflow_executions.show.tabs.samplesheet')
      assert_selector 'table'

      within 'table tbody tr', text: sample33.puid do
        assert_selector 'td:nth-child(4)', text: sample33.metadata['metadatafield1']
        assert_selector 'td:nth-child(5)', text: sample33.metadata['metadatafield2']
        (6..11).each do |i|
          assert_selector "td:nth-child(#{i})", text: ''
        end
      end

      within 'table tbody tr', text: sample34.puid do
        assert_selector 'td:nth-child(4)', text: sample34.metadata['metadatafield1']
        assert_selector 'td:nth-child(5)', text: sample34.metadata['metadatafield2']
        (6..11).each do |i|
          assert_selector "td:nth-child(#{i})", text: ''
        end
      end

      within 'table tbody tr', text: sample35.puid do
        (4..11).each do |i|
          assert_selector "td:nth-child(#{i})", text: ''
        end
      end
      ### ACTIONS AND VERIFY END ###
    end

    test 'default and changed file selection data retained after workflow submitted' do
      # tests submission of file data from default selection, PE file selection change and non-PE file selection change
      ### SETUP START ###
      sample_c = samples(:sampleC)
      attachment_d = attachments(:attachmentD)
      attachment_fwd5 = attachments(:attachmentPEFWD5)
      attachment_rev5 = attachments(:attachmentPEREV5)
      attachment_fwd6 = attachments(:attachmentPEFWD6)
      attachment_rev6 = attachments(:attachmentPEREV6)
      visit namespace_project_samples_url(@jeff_doe_namespace, @project_a)
      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      check "checkbox_sample_#{@sample_a.id}"
      check "checkbox_sample_#{@sample_b.id}"
      check "checkbox_sample_#{sample_c.id}"

      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title', text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # verify samples samplesheet loaded
      assert_selector 'h1.dialog--title',
                      text: I18n.t('workflow_executions.submissions.create.title',
                                   workflow: 'phac-nml/iridanextexample')
      assert_selector 'label', text: I18n.t('components.nextflow.samplesheet_component.label', sample_count: 3)

      fill_in 'workflow_execution_name', with: 'a_new_workflow'
      # verify auto selected attachments
      assert_link "#{@sample_a.id}_fastq_1_file_link", text: @attachment_c.file.filename.to_s
      assert_link "#{@sample_a.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: @attachment_fwd3.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link", text: @attachment_rev3.file.filename.to_s
      assert_link "#{sample_c.id}_fastq_1_file_link", text: attachment_fwd6.file.filename.to_s
      assert_link "#{sample_c.id}_fastq_2_file_link", text: attachment_rev6.file.filename.to_s

      # select non-pe file
      click_link "#{@sample_b.id}_fastq_1_file_link"
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{attachment_d.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')

      # fastq_1 field changed to single-end fastq file, fastq_2 autopopulates to no selected file
      assert_link "#{@sample_b.id}_fastq_1_file_link", text: attachment_d.file.filename.to_s
      assert_link "#{@sample_b.id}_fastq_2_file_link",
                  text: I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file')

      # select different PE file
      click_link "#{sample_c.id}_fastq_1_file_link"
      # verify file selector rendered
      assert_selector '#file_selector_form_dialog'
      within('#file_selector_form_dialog') do
        assert_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')
        # select new attachment
        find("#attachment_id_#{attachment_fwd5.id}").click
        click_button I18n.t('workflow_executions.file_selector.file_selector_dialog.submit_button')
      end
      # verify file selector dialog closed
      assert_no_selector 'h1', text: I18n.t('workflow_executions.file_selector.file_selector_dialog.select_file')

      # fastq_1 field changed to auto-selects fastq_2 to rev PE file
      assert_link "#{sample_c.id}_fastq_1_file_link", text: attachment_fwd5.file.filename.to_s
      assert_link "#{sample_c.id}_fastq_2_file_link", text: attachment_rev5.file.filename.to_s

      click_button I18n.t('workflow_executions.submissions.create.submit')

      assert_selector 'h1', text: I18n.t('shared.workflow_executions.index.title')
      current_workflow = WorkflowExecution.last
      assert_equal 'a_new_workflow', current_workflow.name
      assert_selector 'table tbody tr:first-child th:first-child', text: current_workflow.id
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: current_workflow.name
      click_link current_workflow.id

      assert_selector 'h1', text: current_workflow.name
      click_button I18n.t(:'workflow_executions.show.tabs.samplesheet')

      within 'table tbody tr', text: @sample_a.puid do
        assert_selector 'td:nth-child(2)', text: @attachment_c.file.filename.to_s
        assert_selector 'td:nth-child(3)', text: ''
      end

      within 'table tbody tr', text: @sample_b.puid do
        assert_selector 'td:nth-child(2)', text: attachment_d.file.filename.to_s
        assert_selector 'td:nth-child(3)', text: ''
      end

      within 'table tbody tr', text: sample_c.puid do
        assert_selector 'td:nth-child(2)', text: attachment_fwd5.file.filename.to_s
        assert_selector 'td:nth-child(3)', text: attachment_rev5.file.filename.to_s
      end
      ### ACTIONS AND VERIFY END ###
    end

    test 'chunked samples request' do
      ### SETUP START ###
      user = users(:chunked_samples_doe)
      project = projects(:projectChunkedSamples)
      namespace = namespaces_user_namespaces(:chunked_samples_doe_namespace)
      login_as user
      ensure_project_has_samples!(project, count: 1002)
      visit namespace_project_samples_url(namespace, project)

      # verify samples table loaded
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 1002,
                                                                                      locale: user.locale))
      # select samples
      click_button I18n.t('common.controls.select_all')

      assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'strong[data-selection-target="selected"]', text: 1002

      # launch workflow execution dialog
      click_on I18n.t(:'projects.samples.index.workflows.button_sr')

      assert_selector 'h1.dialog--title',
                      text: I18n.t(:'workflow_executions.submissions.pipeline_selection.title')
      assert_button text: 'phac-nml/iridanextexample', count: 3
      click_button 'phac-nml/iridanextexample', match: :first
      ### SETUP END ###

      ### VERIFY START ###
      assert_selector 'dialog h1', text: 'phac-nml/iridanextexample'
      assert_selector 'label', text: I18n.t('components.nextflow.samplesheet_component.label', sample_count: 1002)

      # strip tags removes space before "Samplesheet" in:
      # "...nts for %{count} samples, this may take a bit of time. Samplesheet is ready."
      # so we have to re-add the space for the assertion
      expected_text = strip_tags(
        I18n.t('components.nextflow_component.loading_complete.alert_message_html', count: 1002)
      )
      expected_text[expected_text.index('.')] = '. '
      if has_selector?('div', text: I18n.t('components.nextflow_component.loading_samplesheet', count: 1002),
                              wait: 0.25.seconds)
        assert_no_selector 'div',
                           text: I18n.t('components.nextflow_component.loading_samplesheet', count: 1002)

        assert_text expected_text
        assert_selector '#pagination-page-selector option', count: 201
      end

      ### VERIFY END ###
    end
  end
end
