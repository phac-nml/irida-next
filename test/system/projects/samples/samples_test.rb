# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    class SamplesTest < ApplicationSystemTestCase
      include ActionView::Helpers::SanitizeHelper

      setup do
        @user = users(:john_doe)
        login_as @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample30 = samples(:sample30)
        @project = projects(:project1)
        @project2 = projects(:project2)
        @namespace = groups(:group_one)
      end

      test 'samples index table' do
        freeze_time
        visit namespace_project_samples_url(@namespace, @project)

        # verifies navigation to page
        assert_selector 'h1', text: I18n.t('projects.samples.index.title')

        # samples table
        within('#samples-table table') do
          # headers
          within('thead tr:first-child') do
            assert_selector 'th:first-child', text: I18n.t('samples.table_component.puid').upcase
            assert_selector 'th:nth-child(2)', text: I18n.t('samples.table_component.name').upcase
            assert_selector 'th:nth-child(3)', text: I18n.t('samples.table_component.created_at').upcase
            assert_selector 'th:nth-child(4)', text: I18n.t('samples.table_component.updated_at').upcase
            assert_selector 'th:nth-child(5)', text: I18n.t('samples.table_component.attachments_updated_at').upcase
            assert_selector 'th:last-child', text: I18n.t('samples.table_component.action').upcase
          end
          within('tbody') do
            # rows
            assert_selector '#samples-table table tbody tr', count: 3
            # row contents
            within("tr[id='#{@sample1.id}']") do
              assert_selector 'th:first-child', text: @sample1.puid
              assert_selector 'td:nth-child(2)', text: @sample1.name
              assert_selector 'td:nth-child(3)', text: I18n.l(@sample1.created_at.localtime, format: :full_date)
              # assert_selector 'td:nth-child(4)', text: "yesterday at #{Time.now.strftime('%-I:%M%P')}"
              assert_selector 'td:nth-child(5)', text: '2 hours ago'
              # actions tested by role in separate test
            end
          end
        end

        # pagy
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
      end

      test 'edit and delete row actions render for user with role == Owner in samples table' do
        visit namespace_project_samples_url(@namespace, @project)

        within("tr[id='#{@sample1.id}'] td:last-child") do
          assert_selector 'a', text: I18n.t('projects.samples.index.edit_button')
          assert_selector 'a', text: I18n.t('projects.samples.index.remove_button')
        end
      end

      test 'edit row action render for user with role == Maintainer in samples table' do
        login_as users(:joan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        within("tr[id='#{@sample1.id}'] td:last-child") do
          assert_selector 'a', text: I18n.t('projects.samples.index.edit_button')
          assert_no_selector 'a', text: I18n.t('projects.samples.index.remove_button')
        end
      end

      test 'no row actions for user with role < Maintainer in samples table' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)
        within('#samples-table table thead tr:first-child') do
          # attachments updated at is the last column, action column does not exist
          assert_selector 'th:last-child', text: I18n.t('samples.table_component.attachments_updated_at').upcase
          assert_no_selector 'th:last-child', text: I18n.t('samples.table_component.action').upcase
        end
        within("tr[id='#{@sample1.id}'] td:last-child") do
          assert_no_selector 'a', text: I18n.t('projects.samples.index.edit_button')
          assert_no_selector 'a', text: I18n.t('projects.samples.index.remove_button')
        end
      end

      test 'User with role >= Maintainer sees select and deselect buttons for samples table' do
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'form#select-all-form'
        assert_selector 'form#deselect-all-form'
      end

      test 'User with role < Maintainer does not see select and deselect buttons for samples table' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'form#select-all-form'
        assert_no_selector 'form#deselect-all-form'
      end

      test 'User with role >= Maintainer sees sample table checkboxes' do
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'input#select-page'
        assert_selector "input#sample_#{@sample1.id}"
      end

      test 'User with role < Maintainer does not see sample table checkboxes' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'input#select-page'
        assert_no_selector "input#sample_#{@sample1.id}"
      end

      test 'User with role >= Analyst sees workflow execution link in samples index' do
        login_as users(:james_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'span[class="sr-only"]', text: I18n.t('projects.samples.index.workflows.button_sr')
      end

      test 'User with role < Analyst does not see workflow execution link in samples index' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'span[class="sr-only"]', text: I18n.t('projects.samples.index.workflows.button_sr')
      end

      test 'User with role >= Analyst sees create export button in samples index' do
        login_as users(:james_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label')
      end

      test 'User with role < Analyst does not see create export button in samples index' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'button', text: I18n.t('projects.samples.index.create_export_button.label')
      end

      test 'User with role >= Maintainer sees import metadata link in samples index' do
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'a', text: I18n.t('projects.samples.index.import_metadata_button')
      end

      test 'User with role < Maintainer does not see import metadata link in samples index' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'a', text: I18n.t('projects.samples.index.import_metadata_button')
      end

      test 'User with role >= Maintainer sees new sample button in samples index' do
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'a', text: I18n.t('projects.samples.index.new_button')
      end

      test 'User with role < Maintainer does not see new sample button in samples index' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'a', text: I18n.t('projects.samples.index.new_button')
      end

      test 'User with role >= Maintainer sees delete samples button in samples index' do
        visit namespace_project_samples_url(@namespace, @project)

        assert_selector 'a', text: I18n.t('projects.samples.index.delete_samples_button')
      end

      test 'User with role < Maintainer does not see delete samples button in samples index' do
        login_as users(:ryan_doe)
        visit namespace_project_samples_url(@namespace, @project)

        assert_no_selector 'a', text: I18n.t('projects.samples.index.delete_samples_button')
      end

      test 'cannot access project samples' do
        login_as users(:user_no_access)

        visit namespace_project_samples_url(@namespace, @project)

        assert_text I18n.t(:'action_policy.policy.project.sample_listing?', name: @project.name)
      end

      test 'should create sample' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        ### setup end ###

        ### actions start ###
        # launch dialog
        click_on I18n.t('projects.samples.index.new_button')

        # fill new sample fields
        fill_in I18n.t('activerecord.attributes.sample.description'), with: 'A sample description'
        fill_in I18n.t('activerecord.attributes.sample.name'), with: 'New Name'
        click_on I18n.t('projects.samples.new.submit_button')
        ### actions end ###

        ### results start ###
        # flash msg
        assert_text I18n.t('projects.samples.create.success')
        # verify redirect to sample show page after successful sample creation
        assert_selector 'h1', text: 'New Name'
        # verify sample exists in table
        visit namespace_project_samples_url(@namespace, @project)
        within('#samples-table table tbody') do
          assert_text 'New Name'
        end
        ### results end ###
      end

      test 'should update Sample' do
        ### setup start ###
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        ### setup end ###

        ### actions start ###
        # nav to edit sample page
        click_on I18n.t('projects.samples.show.edit_button')

        # change current sample properties with new ones
        fill_in 'Description', with: 'A new description'
        fill_in 'Name', with: 'New Sample Name'
        click_on I18n.t('projects.samples.edit.submit_button')
        ### actions end ###

        ### results start ###
        # flash msg
        assert_text I18n.t('projects.samples.update.success')

        # verify redirect to sample show page and updated sample state
        assert_selector 'h1', text: 'New Sample Name'
        assert_text 'A new description'
        ### results end ###
      end

      test 'should destroy Sample from sample show page' do
        ### setup start ###
        # nav to samples index and verify sample exists within table
        visit namespace_project_samples_url(@namespace, @project)
        assert_selector "#samples-table table tbody tr[id='#{@sample1.id}']"
        assert_selector '#samples-table table tbody tr', count: 3

        # nav to sample show
        visit namespace_project_sample_url(@namespace, @project, @sample1)
        ### setup end ###

        ### actions start ##
        click_link I18n.t(:'projects.samples.index.remove_button')

        within('#turbo-confirm[open]') do
          click_button I18n.t(:'components.confirmation.confirm')
        end
        ### actions end ###

        ### verify start ###
        # flash msg
        assert_text I18n.t('projects.samples.deletions.destroy.success', sample_name: @sample1.name,
                                                                         project_name: @project.namespace.human_name)
        # deleted sample row no longer exists
        assert_no_selector "#samples-table table tbody tr[id='#{@sample1.id}']"
        # redirected to samples index
        assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
        # remaining samples still appear on table
        assert_selector '#samples-table table tbody tr', count: 2
        ### verify end ###
      end

      test 'should destroy Sample from sample listing page' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)

        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###
        within("tr[id='#{@sample1.id}']") do
          click_link I18n.t('projects.samples.index.remove_button')
        end

        within('#dialog') do
          assert_text I18n.t('projects.samples.deletions.new_deletion_dialog.description', sample_name: @sample1.name)
          click_button I18n.t('projects.samples.deletions.new_deletion_dialog.submit_button')
        end
        ### setup end ###

        ### verify start ###
        # flash msg
        assert_text I18n.t('projects.samples.deletions.destroy.success', sample_name: @sample1.name,
                                                                         project_name: @project.namespace.human_name)
        # sample no longer exists
        assert_no_selector "tr[id='#{@sample1.id}']"
        # still on samples index page
        assert_selector 'h1', text: I18n.t(:'projects.samples.index.title'), count: 1
        # remaining samples still in table
        assert_selector '#samples-table table tbody tr', count: 2
        ### verify end ###
      end

      test 'should transfer samples' do
        ### setup start ###
        # show destination project has 20 samples prior to transfer
        visit namespace_project_samples_url(@namespace, @project2)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                             locale: @user.locale))
        # originating project has 3 samples prior to transfer
        visit namespace_project_samples_url(
          @namespace, @project
        )
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### actions start ###
        samples = @project.samples.pluck(:puid, :name)
        within('#samples-table table tbody') do
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.transfer_button')
        within('#dialog') do
          # verify 'plural' form of description renders
          assert_text I18n.t('projects.samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                                           '3')
          # verify sample puid and name are listed in dialog list
          within %(turbo-frame[id="list_selections"]) do
            samples.each do |sample|
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          # select destination project
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
          click_on I18n.t('projects.samples.transfers.dialog.submit_button')
        end
        ### actions end ###

        ### verify start ###
        # flash msg
        assert_text I18n.t('projects.samples.transfers.create.success')
        # originating project no longer has samples
        assert_text I18n.t('projects.samples.index.no_samples')

        visit namespace_project_samples_url(@namespace, @project2)
        within '#samples-table table tbody' do
          samples.each do |sample|
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        ### verify end ###
      end

      test 'transfer dialog with single sample' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        ### setup end ###

        ### actions start ###
        within '#samples-table table tbody' do
          all('input[type="checkbox"]')[0].click
        end
        click_link I18n.t('projects.samples.index.transfer_button')
        ### actions end ###

        ### verify start ###
        within('#dialog') do
          assert_text I18n.t('projects.samples.transfers.dialog.description.singular')
        end
        ### verify end ###
      end

      test 'should not transfer samples with session storage cleared' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### actions start ###
        within '#samples-table table tbody' do
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        Capybara.execute_script 'sessionStorage.clear()'
        click_link I18n.t('projects.samples.index.transfer_button')
        within('#dialog') do
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{@project2.full_path}']").click
          click_on I18n.t('projects.samples.transfers.dialog.submit_button')
          ### actions end ###

          ### verify start ###
          # samples listing should no longer appear in dialog
          assert_no_selector '#list_selections'
          # error msg displayed in dialog
          assert_text I18n.t('projects.samples.transfers.create.no_samples_transferred_error')
        end
        ### verify end ###
      end

      test 'transfer samples with and without same name in destination project' do
        # only samples without a matching name will transfer

        ### setup start ###
        namespace = groups(:subgroup1)
        project25 = projects(:project25)

        # verify only 2 samples exist in destination project
        visit namespace_project_samples_url(namespace, project25)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                             locale: @user.locale))
        visit namespace_project_samples_url(@namespace, @project)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### actions start ###
        within '#samples-table table tbody' do
          all('input[type=checkbox]').each do |checkbox|
            checkbox.click unless checkbox.checked?
          end
        end
        click_link I18n.t('projects.samples.index.transfer_button')
        within('#dialog') do
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project25.full_path}']").click
          click_on I18n.t('projects.samples.transfers.dialog.submit_button')
        end
        ### actions end ###

        ### verify start ###
        within('#dialog') do
          # error messages in dialog
          assert_text I18n.t('projects.samples.transfers.create.error')
          # colon is removed from translation in UI
          assert_text I18n.t('services.samples.transfer.sample_exists', sample_puid: @sample30.puid,
                                                                        sample_name: @sample30.name).gsub(':', '')
        end

        # verify sample1 and 2 transferred, sample 30 did not
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1, locale: @user.locale))
        assert_no_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"

        # destination project
        visit namespace_project_samples_url(namespace, project25)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                             locale: @user.locale))
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"
        ### verify end ###
      end

      test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
        ### setup start ###
        login_as users(:user28)
        namespace = groups(:group_hotel)
        project = projects(:projectHotel)
        visit namespace_project_samples_url(namespace, project)
        ### setup end ###

        ### actions start ###
        within '#samples-table table tbody' do
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.transfer_button')
        ### actions end ###

        ### verify start ###
        within('#dialog') do
          # no available destination projects
          assert_selector "input[placeholder='#{I18n.t('projects.samples.transfers.dialog.no_available_projects')}']"
        end
        ### verify end ###
      end

      test 'empty state of transfer sample project selection' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        ### setup end ###

        ### actions start ###
        within '#samples-table table tbody' do
          # check samples
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end

        # launch dialog
        click_link I18n.t('projects.samples.index.transfer_button')
        within('#dialog') do
          # fill destination input
          find('input#select2-input').fill_in with: 'invalid project name or puid'
          ### actions end ###

          ### verify start ###
          assert_text I18n.t('projects.samples.transfers.dialog.empty_state')
          ### verify end ###
        end
      end

      test 'can search the list of samples by name' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        # partial name search
        filter_text = @sample1.name[-3..-1]

        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        assert_selector '#samples-table table tbody tr', count: 3
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
        ### setup end ###

        ### actions start ###
        # apply filter
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: filter_text
        find('input.t-search-component').native.send_keys(:return)
        ### actions end ###

        ### verify start ###
        # verify table only contains sample1
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1, locale: @user.locale))
        assert_selector '#samples-table table tbody tr', count: 1
        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"
        ### verify end ###
      end

      test 'can search the list of samples by metadata field and value presence when metadata is toggled' do
        # also tests that metadata toggle persist through other actions (filter) and page refresh
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        filter_text = 'metadatafield1:value1'

        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        assert_selector '#samples-table table tbody tr', count: 3
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
        ### setup end ###

        ### actions and verify start ###
        # toggle metadata on
        find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click
        # verify all 3 samples are still in table
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        assert_selector '#samples-table table tbody tr', count: 3
        # verify metadata fields are now present
        assert_selector '#samples-table table thead tr th', count: 8

        # apply filter
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: filter_text
        find('input.t-search-component').native.send_keys(:return)

        # verify table only has sample30
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                             locale: @user.locale))
        assert_selector '#samples-table table tbody tr', count: 1
        assert_no_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"

        # verify filter input persists
        assert_selector %(input.t-search-component) do |input|
          assert_equal filter_text, input['value']
        end
        ### actions and verify end ###
      end

      test 'can change limit/pagination and then filter by id' do
        # tests limit change and that it persists through other actions (filter)
        ### setup start ###
        sample3 = samples(:sample3)
        visit namespace_project_samples_url(@namespace, @project2)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                             locale: @user.locale))
        ### setup end ###

        ### actions and verify start ###
        within('div#limit-component') do
          # set table limit to 10
          find('button').click
          click_link '10'
        end

        # verify limit is set to 10
        assert_selector 'div#limit-component button div span', text: '10'
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 10, count: 20,
                                                                             locale: @user.locale))
        # verify table consists of 10 samples per page
        assert_selector '#samples-table table tbody tr', count: 10

        # apply filter
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: sample3.puid
        find('input.t-search-component').native.send_keys(:return)

        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary.one', count: 1, locale: @user.locale))
        assert_selector '#samples-table table tbody tr', count: 1
        assert_selector "tr[id='#{sample3.id}']"
        ### actions and verify end ###
      end

      test 'filter highlighting for sample name' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### actions start ###
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: 'sample'
        find('input.t-search-component').native.send_keys(:return)
        ### actions end ###

        ### verify start ###
        # verify table only contains sample1
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        # checks highlighting
        assert_selector 'mark', text: 'Sample', count: 3
      end

      test 'filter highlighting for sample puid' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### actions start ###
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.puid
        find('input.t-search-component').native.send_keys(:return)
        ### actions end ###

        ### verify start ###
        # verify table only contains sample1
        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                             locale: @user.locale))
        # checks highlighting
        assert_selector 'mark', text: @sample1.puid
      end

      test 'can sort samples' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)

        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### action and verify start ###
        within('tbody tr:first-child th') do
          assert_text @sample1.puid
        end
        click_on I18n.t('samples.table_component.name')

        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
        within('#samples-table table tbody') do
          assert_selector 'tr:first-child th', text: @sample1.puid
          assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
          assert_selector 'tr:nth-child(2) th', text: @sample2.puid
          assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
          assert_selector 'tr:last-child th', text: @sample30.puid
          assert_selector 'tr:last-child td:nth-child(2)', text: @sample30.name
        end

        click_on I18n.t('samples.table_component.name')

        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
        within('#samples-table table tbody') do
          assert_selector 'tr:first-child th', text: @sample30.puid
          assert_selector 'tr:first-child td:nth-child(2)', text: @sample30.name
          assert_selector 'tr:nth-child(2) th', text: @sample2.puid
          assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
          assert_selector 'tr:last-child th', text: @sample1.puid
          assert_selector 'tr:last-child td:nth-child(2)', text: @sample1.name
        end
        ### action and verify end ###
      end

      test 'sort samples attachments_updated_at_nulls_last' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)

        assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                             locale: @user.locale))
        ### setup end ###

        ### action and verify start ###
        within('tbody tr:first-child th') do
          assert_text @sample1.puid
        end
        click_on I18n.t('samples.table_component.attachments_updated_at')

        assert_selector 'table thead th:nth-child(5) svg.icon-arrow_up'
        within('#samples-table table tbody') do
          assert_selector 'tr:first-child th', text: @sample1.puid
          assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
          assert_selector 'tr:nth-child(2) th', text: @sample2.puid
          assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
          assert_selector 'tr:last-child th', text: @sample30.puid
          assert_selector 'tr:last-child td:nth-child(2)', text: @sample30.name
        end

        click_on I18n.t('samples.table_component.attachments_updated_at')

        assert_selector 'table thead th:nth-child(5) svg.icon-arrow_down'
        within('#samples-table table tbody') do
          # order does not change as sample1 is the only sample with attachments_updated_at
          assert_selector 'tr:first-child th', text: @sample1.puid
          assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
          assert_selector 'tr:nth-child(2) th', text: @sample2.puid
          assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
          assert_selector 'tr:last-child th', text: @sample30.puid
          assert_selector 'tr:last-child td:nth-child(2)', text: @sample30.name
        end
        ### action and verify end ###
      end

      test 'can filter and then sort the list of samples by name' do
        # tests that filter persists through other actions (sort)
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
        ### setup end ###

        ### actions start ###
        # apply filter
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.name
        find('input.t-search-component').native.send_keys(:return)

        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"

        # apply sort
        click_on I18n.t('samples.table_component.name')
        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
        ### actions end ###

        ### verify start ###
        # verify table still only contains sample1
        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"

        # verify filter text is still in filter input
        assert_selector %(input.t-search-component) do |input|
          assert_equal @sample1.name, input['value']
        end
        ### verify end ###
      end

      test 'can sort and then filter the list of samples by puid' do
        # tests that sort persists through other actions (filter)
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample30.id}']"
        ### setup end ###

        ### actions start ###
        # apply sort
        click_on I18n.t('samples.table_component.name')
        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

        # apply filter
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: @sample1.puid
        find('input.t-search-component').native.send_keys(:return)
        ### actions end ###

        ### verify start ###
        # verify sort is still applied
        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
        # verify table only contains sample1
        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"
        ### verify end ###
      end

      test 'filter persists through page refresh' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        filter_text = @sample1.name
        ### setup end ###

        ### actions start ###
        # apply filter
        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: filter_text
        find('input.t-search-component').native.send_keys(:return)
        ### actions end ###

        ### verify start ###
        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"

        # refresh
        visit namespace_project_samples_url(@namespace, @project)

        # verify filter is still in input field
        assert_selector %(input.t-search-component) do |input|
          assert_equal filter_text, input['value']
        end
        assert_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample30.id}']"
        ### verify end ###
      end

      test 'sort persists through page refresh' do
        ### setup start ###
        visit namespace_project_samples_url(@namespace, @project)
        ### setup end ###

        ### actions start ###
        # apply sort
        click_on I18n.t('samples.table_component.name')
        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
        assert_selector '#samples-table table tbody th:first-child', text: @sample1.puid
        # change sort order from default sorting
        click_on I18n.t('samples.table_component.name')
        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
        assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
        ### actions end ###

        ### verify start ###

        # refresh
        visit namespace_project_samples_url(@namespace, @project)

        # verify sort is still enabled
        assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'
        # verify table ordering is still in changed/sorted state
        assert_selector '#samples-table table tbody th:first-child', text: @sample30.puid
        ### verify end ###
      end

      test 'should import metadata via csv' do
        visit namespace_project_samples_url(@namespace, @project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
          click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
        end
      end

      test 'should import metadata via xls' do
        visit namespace_project_samples_url(@namespace, @project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xls')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
          click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
        end
      end

      test 'should import metadata via xlsx' do
        visit namespace_project_samples_url(@namespace, @project)

        find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
        assert_selector '#samples-table table thead tr th', count: 8

        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first

        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
          find('#file_import_sample_id_column', wait: 2).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
          click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
        end

        assert_selector 'table thead tr th', count: 10
      end

      test 'should not import metadata via invalid file type' do
        visit namespace_project_samples_url(@namespace, @project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="import_metadata_dialog_alert"]) do
          assert_text I18n.t('services.samples.metadata.import_file.invalid_file_extension')
        end
      end

      test 'should import metadata with ignore empty values' do
        namespace = groups(:subgroup_twelve_a)
        project = projects(:project29)
        sample = samples(:sample32)
        visit namespace_project_samples_url(namespace, project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          check 'Ignore empty values'
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
          click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
        end
        visit namespace_project_sample_url(namespace, project, sample)
        assert_text I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.tabs.metadata')
        within %(turbo-frame[id="table-listing"]) do
          assert_text I18n.t('projects.samples.show.table_header.key').upcase
          assert_selector 'table#metadata-table tbody tr', count: 3
          within('table#metadata-table tbody tr:first-child td:nth-child(2)') do
            assert_text 'metadatafield1'
          end
          within('table#metadata-table tbody tr:first-child td:nth-child(3)') do
            assert_text 'value1'
          end
        end
      end

      test 'should import metadata without ignore empty values' do
        namespace = groups(:subgroup_twelve_a)
        project = projects(:project29)
        sample = samples(:sample32)
        visit namespace_project_samples_url(namespace, project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_empty_values.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          assert_not find_field('Ignore empty values').checked?
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
          click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
        end
        visit namespace_project_sample_url(namespace, project, sample)
        assert_text I18n.t('projects.samples.show.tabs.metadata')
        click_on I18n.t('projects.samples.show.tabs.metadata')
        within %(turbo-frame[id="table-listing"]) do
          assert_text I18n.t('projects.samples.show.table_header.key').upcase
          assert_selector 'table#metadata-table tbody tr', count: 2
          assert_no_text 'metadatafield1'
        end
      end

      test 'should not import metadata with duplicate header errors' do
        visit namespace_project_samples_url(@namespace, @project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="import_metadata_dialog_alert"]) do
          assert_text I18n.t('services.samples.metadata.import_file.duplicate_column_names')
        end
      end

      test 'should not import metadata with missing metadata row errors' do
        visit namespace_project_samples_url(@namespace, @project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="import_metadata_dialog_alert"]) do
          assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_row')
        end
      end

      test 'should not import metadata with missing metadata column errors' do
        visit namespace_project_samples_url(@namespace, @project)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="import_metadata_dialog_alert"]) do
          assert_text I18n.t('services.samples.metadata.import_file.missing_metadata_column')
        end
      end

      test 'should partially import metadata with missing sample errors' do
        visit namespace_project_samples_url(@namespace, @project)

        find('label', text: I18n.t('projects.samples.shared.metadata_toggle.label')).click
        assert_selector '#samples-table table thead tr th', count: 8

        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/mixed_project_samples.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
          click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
        end
        assert_selector '#samples-table table thead tr th', count: 9
      end

      test 'should not import metadata with analysis values' do
        subgroup12aa = groups(:subgroup_twelve_a_a)
        project31 = projects(:project31)
        Project.reset_counters(project31.id, :samples_count)
        visit namespace_project_samples_url(subgroup12aa, project31)
        click_link I18n.t('projects.samples.index.import_metadata_button'), match: :first
        within('div[data-metadata--file-import-loaded-value="true"]') do
          attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_analysis_values.csv')
          find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
          click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
          click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
        end
      end

      test 'should clone multiple samples' do
        project2 = projects(:project2)
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.clone_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          assert_text I18n.t(
            'projects.samples.clones.dialog.description.plural'
          ).gsub! 'COUNT_PLACEHOLDER', '3'
          within %(turbo-frame[id="list_selections"]) do
            samples = @project.samples.pluck(:puid, :name)
            samples.each do |sample|
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
          click_on I18n.t('projects.samples.clones.dialog.submit_button')
        end
        assert_text I18n.t('projects.samples.clones.create.success')
      end

      test 'should clone single sample' do
        project2 = projects(:project2)
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          all('input[type="checkbox"]')[0].click
        end
        click_link I18n.t('projects.samples.index.clone_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          assert_text I18n.t('projects.samples.clones.dialog.description.singular')
          within %(turbo-frame[id="list_selections"]) do
            assert_text @sample1.name
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
          click_on I18n.t('projects.samples.clones.dialog.submit_button')
        end
        assert_text I18n.t('projects.samples.clones.create.success')
      end

      test 'should not clone samples with session storage cleared' do
        project2 = projects(:project2)
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        Capybara.execute_script 'sessionStorage.clear()'
        click_link I18n.t('projects.samples.index.clone_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project2.full_path}']").click
          click_on I18n.t('projects.samples.clones.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_no_selector "turbo-frame[id='list_selections']"
          assert_text I18n.t('projects.samples.clones.create.no_samples_cloned_error')
          errors = project2.errors.full_messages_for(:base)
          errors.each { |error| assert_text error }
          click_on I18n.t('projects.samples.shared.errors.ok_button')
        end
      end

      test 'should not clone some samples' do
        project25 = projects(:project25)
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.clone_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          within %(turbo-frame[id="list_selections"]) do
            samples = @project.samples.pluck(:puid, :name)
            samples.each do |sample|
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          find('input#select2-input').click
          find("button[data-viral--select2-primary-param='#{project25.full_path}']").click
          click_on I18n.t('projects.samples.clones.dialog.submit_button')
        end
        within %(turbo-frame[id="samples_dialog"]) do
          assert_text I18n.t('projects.samples.clones.create.error')
          errors = @project.errors.full_messages_for(:samples)
          errors.each { |error| assert_text error }
          click_on I18n.t('projects.samples.shared.errors.ok_button')
        end
      end

      test 'empty state of clone sample project selection' do
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.clone_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          within %(turbo-frame[id="list_selections"]) do
            samples = @project.samples.pluck(:puid, :name)
            samples.each do |sample|
              assert_text sample[0]
              assert_text sample[1]
            end
          end
          find('input#select2-input').fill_in with: 'invalid project name or puid'
          assert_text I18n.t('projects.samples.clones.dialog.empty_state')
        end
      end

      test 'no available destination projects to clone samples' do
        sign_in users(:jean_doe)
        namespace = namespaces_user_namespaces(:john_doe_namespace)
        project = projects(:john_doe_project2)
        Project.reset_counters(project.id, :samples_count)
        visit namespace_project_samples_url(namespace, project)
        within '#samples-table table tbody' do
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.clone_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          assert "input[placeholder='#{I18n.t('projects.samples.clones.dialog.no_available_projects')}']"
        end
      end

      test 'filtering samples by list of sample puids' do
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          assert_selector 'tr th', text: @sample1.puid
          assert_selector 'tr th', text: @sample2.puid
        end
        click_button I18n.t(:'components.list_filter.title')
        within '#list-filter-dialog' do
          assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
          fill_in I18n.t(:'components.list_filter.description'), with: "#{@sample1.puid}, #{@sample2.puid}"
          assert_selector 'span.label', count: 1
          assert_selector 'span.label', text: @sample1.puid
          find("input[name='q[name_or_puid_in][]']").text @sample2.puid
          click_button I18n.t(:'components.list_filter.apply')
        end
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 2
        end
        click_button I18n.t(:'components.list_filter.title')
        within '#list-filter-dialog' do
          assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
          click_button I18n.t(:'components.list_filter.clear')
          click_button I18n.t(:'components.list_filter.apply')
        end
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
        end
      end

      test 'selecting / deselecting all samples' do
        visit namespace_project_samples_url(@namespace, @project)
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 0
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end
        click_button I18n.t(:'projects.samples.index.select_all_button')
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]:checked', count: 3
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '3'
        end
        within 'tbody' do
          first('input[name="sample_ids[]"]').click
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '2'
        end
        click_button I18n.t(:'projects.samples.index.select_all_button')
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 3
        end
        click_button I18n.t(:'projects.samples.index.deselect_all_button')
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 0
        end
      end

      test 'selecting / deselecting a page of samples' do
        visit namespace_project_samples_url(@namespace, @project)
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 0
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end
        find('input[name="select-page"]').click
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]:checked', count: 3
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '3'
        end
        within 'tbody' do
          first('input[name="sample_ids[]"]').click
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '2'
        end
        find('input[name="select-page"]').click
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 3
        end
        find('input[name="select-page"]').click
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 0
        end
      end

      test 'selecting samples while filtering' do
        visit namespace_project_samples_url(@namespace, @project)
        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 3
          assert_selector 'input[name="sample_ids[]"]:checked', count: 0
        end
        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end

        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: samples(:sample1).name
        find('input.t-search-component').native.send_keys(:return)

        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]', count: 1
          assert_selector 'input[name="sample_ids[]"]:checked', count: 0
        end

        click_button I18n.t(:'projects.samples.index.select_all_button')

        within 'tbody' do
          assert_selector 'input[name="sample_ids[]"]:checked', count: 1
        end
        within 'tfoot' do
          assert_text 'Samples: 1'
          assert_selector 'strong[data-selection-target="selected"]', text: '1'
        end

        fill_in placeholder: I18n.t(:'projects.samples.index.search.placeholder'), with: ' '
        find('input.t-search-component').native.send_keys(:return)

        within 'tfoot' do
          assert_text 'Samples: 3'
          assert_selector 'strong[data-selection-target="selected"]', text: '0'
        end
      end

      test 'action links are disabled when a project does not contain any samples' do
        login_as users(:empty_doe)

        visit namespace_project_samples_url(namespace_id: groups(:empty_group).path,
                                            project_id: projects(:empty_project).path)

        assert_no_button I18n.t(:'projects.samples.index.clone_button')
        assert_no_button I18n.t(:'projects.samples.index.transfer_button')
        assert_text I18n.t('projects.samples.index.create_export_button.label')
        assert_selector 'button.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                        text: I18n.t('projects.samples.index.create_export_button.label')
      end

      test 'delete multiple samples' do
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          assert_text @sample1.name
          assert_text @sample2.name
          assert_text @sample30.name
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end
        click_link I18n.t('projects.samples.index.delete_samples_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.title')
          assert_text I18n.t(
            'projects.samples.deletions.new_multiple_deletions_dialog.description.plural'
          ).gsub! 'COUNT_PLACEHOLDER', '3'
          assert_text @sample1.name
          assert_text @sample1.puid
          assert_text @sample2.name
          assert_text @sample2.puid
          assert_text @sample30.name
          assert_text @sample30.puid

          click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
        end
        assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

        within 'div[role="alert"]' do
          assert_text I18n.t('projects.samples.index.no_samples')
          assert_text I18n.t('projects.samples.index.no_associated_samples')
        end
      end

      test 'delete single sample with checkbox and delete samples button' do
        visit namespace_project_samples_url(@namespace, @project)
        within('tbody') do
          assert_selector 'tr', count: 3
          assert_text @sample1.name
          assert_text @sample2.name
          assert_text @sample30.name
          within 'tr:first-child' do
            all('input[type="checkbox"]')[0].click
          end
        end
        click_link I18n.t('projects.samples.index.delete_samples_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.title')
          assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.description.singular',
                             sample_name: @sample1.name)
          within %(turbo-frame[id="list_selections"]) do
            assert_text @sample1.puid
          end

          click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
        end

        assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

        within 'tbody' do
          assert_selector 'tr', count: 2
          assert_no_text @sample1.name
          assert_text @sample2.name
          assert_text @sample30.name
        end
      end

      test 'delete single sample with remove link while all samples selected followed by multiple deletion' do
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          assert_text @sample1.name
          assert_text @sample2.name
          assert_text @sample30.name
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
        end

        assert find('input#select-page').checked?

        within '#samples-table table tbody tr:first-child' do
          click_link I18n.t('projects.samples.index.remove_button')
        end

        within '#dialog' do
          click_button I18n.t('projects.samples.deletions.new_deletion_dialog.submit_button')
        end

        within '#samples-table table tbody' do
          assert_selector 'tr', count: 2
          assert_no_text @sample1.name
          assert all('input[type="checkbox"]')[0].checked?
          assert all('input[type="checkbox"]')[1].checked?
        end

        assert find('input#select-page').checked?

        click_link I18n.t('projects.samples.index.delete_samples_button'), match: :first
        within('span[data-controller-connected="true"] dialog') do
          assert_text I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.title')
          assert_text I18n.t(
            'projects.samples.deletions.new_multiple_deletions_dialog.description.plural'
          ).gsub! 'COUNT_PLACEHOLDER', '2'
          assert_text @sample2.name
          assert_text @sample30.name
          assert_no_text @sample1.name
          click_on I18n.t('projects.samples.deletions.new_multiple_deletions_dialog.submit_button')
        end
        assert_text I18n.t('projects.samples.deletions.destroy_multiple.success')

        within 'div[role="alert"]' do
          assert_text I18n.t('projects.samples.index.no_samples')
          assert_text I18n.t('projects.samples.index.no_associated_samples')
        end

        assert_selector 'a.cursor-not-allowed.pointer-events-none', count: 4
        assert_selector 'button.cursor-not-allowed.pointer-events-none', count: 1
      end

      test 'delete single attachment with remove link while all attachments selected followed by multiple deletion' do
        visit namespace_project_sample_url(@namespace, @project, @sample1)

        within('#attachments-table-body') do
          assert_link text: I18n.t('projects.samples.attachments.attachment.delete'), count: 2
          all('input[type=checkbox]').each { |checkbox| checkbox.click unless checkbox.checked? }
          click_on I18n.t('projects.samples.attachments.attachment.delete'), match: :first
        end

        within('#dialog') do
          assert_text I18n.t('projects.samples.attachments.delete_attachment_modal.description')
          click_button I18n.t('projects.samples.attachments.delete_attachment_modal.submit_button')
        end

        assert_text I18n.t('projects.samples.attachments.destroy.success', filename: 'test_file_A.fastq')
        within('#table-listing') do
          assert_no_text 'test_file_A.fastq'
          assert_text 'test_file_B.fastq'
        end

        click_link I18n.t('projects.samples.show.delete_files_button'), match: :first

        within('#dialog') do
          assert_text 'test_file_B.fastq'
          assert_no_text 'test_file_A.fastq'
          click_button I18n.t('projects.samples.attachments.deletions.modal.submit_button')
        end

        assert_text I18n.t('projects.samples.attachments.deletions.destroy.success')
        assert_no_text 'test_file_A.fastq'
        assert_no_text 'test_file_B.fastq'
        assert_text I18n.t('projects.samples.show.no_files')
        assert_selector 'a.cursor-not-allowed.pointer-events-none', count: 2
      end

      test 'can filter by large list of sample names or ids' do
        visit namespace_project_samples_url(@namespace, @project)
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
          assert_selector 'tr th', text: @sample1.puid
          assert_selector 'tr th', text: @sample2.puid
        end
        click_button I18n.t(:'components.list_filter.title')
        within '#list-filter-dialog' do |dialog|
          assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
          fill_in I18n.t(:'components.list_filter.description'), with: long_filter_text
          assert_selector 'span.label', count: 500
          dialog.scroll_to(dialog.find('button', text: I18n.t(:'components.list_filter.apply')), align: :bottom)
          click_button I18n.t(:'components.list_filter.apply')
        end
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 1
        end
        click_button I18n.t(:'components.list_filter.title')
        within '#list-filter-dialog' do |dialog|
          assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
          dialog.scroll_to dialog.find('button', text: I18n.t(:'components.list_filter.apply'))

          click_button I18n.t(:'components.list_filter.clear')
          click_button I18n.t(:'components.list_filter.apply')
        end
        within '#samples-table table tbody' do
          assert_selector 'tr', count: 3
        end
      end

      def long_filter_text
        text = (1..500).map { |n| "sample#{n}" }.join(', ')
        "#{text}, #{@sample1.name}" # Need to comma to force the tag to be created
      end
    end
  end
end
