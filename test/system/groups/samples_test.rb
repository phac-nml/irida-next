# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    def setup # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      Flipper.enable(:metadata_import_field_selection)
      Flipper.enable(:batch_sample_spreadsheet_import)

      @user = users(:john_doe)
      login_as @user
      @group = groups(:group_one)
      @project1 = projects(:project1)
      @project2 = projects(:project2)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample3 = samples(:sample3)
      @sample9 = samples(:sample9)
      @sample25 = samples(:sample25)
      @sample28 = samples(:sample28)
      @sample30 = samples(:sample30)
      @sample31 = samples(:sample31)

      Flipper.enable(:progress_bars)
      Flipper.enable(:group_samples_transfer)
      Flipper.enable(:group_samples_destroy)
      Flipper.enable(:group_samples_clone)
    end

    def retrieve_puids
      puids = []
      within('table tbody') do
        (1..4).each do |n|
          puids << first("tr:nth-child(#{n}) th").text
        end
      end
      puids
    end

    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'span.cursor-not-allowed',
                      text: I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'tbody > tr', count: 6
      click_on I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'tbody > tr', count: 20

      click_link samples(:sample3).name
      assert_selector 'h1', text: samples(:sample3).name
    end

    test 'visiting the index of a group which has other groups/projects linked to it' do
      login_as users(:david_doe)
      # group_one shared with group
      group = groups(:david_doe_group_four)
      visit group_samples_url(group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample1).name
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'span.cursor-not-allowed',
                      text: I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'tbody > tr', count: 6
      assert_text samples(:sample28).name
      click_on I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'tbody > tr', count: 20

      click_link samples(:sample1).name
      assert_selector 'h1', text: samples(:sample1).name

      visit group_samples_url(group)

      click_link samples(:sample1).name
      assert_selector 'h1', text: samples(:sample1).name

      visit group_samples_url(group)

      assert_selector 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'span.cursor-not-allowed',
                      text: I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))

      click_link samples(:sample28).name
      assert_selector 'h1', text: samples(:sample28).name
    end

    test 'User with role >= Analyst does not see workflow executions button' do
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'span', text: I18n.t('projects.samples.index.workflows.button_sr')
    end

    test 'User with role < Analyst does not see workflow executions button' do
      login_as users(:ryan_doe)
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_no_selector 'span', text: I18n.t('projects.samples.index.workflows.button_sr')
    end

    test 'User with role >= Analyst sees sample actions dropdown' do
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'span', text: I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'User with role < Analyst does not see sample actions dropdown' do
      login_as users(:ryan_doe)
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_no_selector 'span', text: I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'User with role >= Maintainer sees copy samples button' do
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button', text: I18n.t('shared.samples.actions_dropdown.clone')
    end

    test 'User with role < Maintainer does not see delete samples button' do
      user = users(:ryan_doe)
      login_as user
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: user.locale))

      assert_no_selector 'a', text: I18n.t('shared.samples.actions_dropdown.clone')
    end

    test 'cannot access group samples' do
      login_as users(:user_no_access)

      visit group_samples_url(@group)

      assert_text I18n.t(:'action_policy.policy.group.sample_listing?', name: @group.name)
    end

    test 'User with role == Owner sees delete samples button' do
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button', text: I18n.t('shared.samples.actions_dropdown.delete_samples')
    end

    test 'User with role < Owner does not see delete samples button' do
      user = users(:joan_doe)
      login_as user
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label', locale: user.locale)
      assert_no_selector 'button', text: I18n.t('shared.samples.actions_dropdown.delete_samples', locale: user.locale)
    end

    test 'can search the list of samples by name' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
        assert_text @sample1.name
        assert_text @sample2.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text 'Samples: 13'
      within('table tbody') do
        assert_selector 'tr', count: 13

        assert_text @sample1.name
        assert_no_text @sample2.name
      end
    end

    test 'can sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      # Because PUIDs are not always generated the same, issues regarding order have occurred when hard testing
      # the expected ordering of samples based on PUID. To resolve this, we will gather the first 4 PUIDs and ensure
      # they are ordered as expected against one another.
      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      click_on I18n.t(:'samples.table_component.puid')
      assert_selector 'table thead th:first-child svg.arrow-up-icon'
      puids = retrieve_puids
      (puids.length - 1).times do |n|
        assert puids[n] < puids[n + 1]
      end

      click_on I18n.t(:'samples.table_component.puid')
      assert_selector 'table thead th:first-child svg.arrow-down-icon'
      puids = retrieve_puids
      (puids.length - 1).times do |n|
        assert puids[n] > puids[n + 1]
      end

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-down-icon'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end
    end

    test 'can filter by name and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text 'Samples: 13'
      within('table tbody') do
        assert_selector 'tr', count: 13

        assert_text @sample1.name
        assert_no_text @sample2.name
      end

      assert_no_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      assert_selector 'tbody tr:first-child th', text: @sample1.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample1.name

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-down-icon'

      assert_selector 'tbody tr:last-child th', text: @sample1.puid
      assert_selector 'tbody tr:last-child td:nth-child(2)', text: @sample1.name
    end

    test 'can filter by puid and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 1
        assert_text @sample1.name
        assert_no_text @sample2.name
      end
      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      within('table tbody') do
        assert_selector 'tr', count: 1
      end
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
    end

    test 'can change pagination and then filter by puid' do
      visit group_samples_url(@group)

      within('div#limit-component') do
        select '10', from: 'limit'
      end

      assert_selector 'div#limit-component select option[selected]', text: '10'
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 10
        assert_text @sample1.puid
        assert_text @sample2.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 1
        assert_text @sample1.name
        assert_no_text @sample2.name
      end
      assert_selector 'div#limit-component select option[selected]', text: '10'
    end

    test 'can change pagination and then toggle metadata' do
      visit group_samples_url(@group)

      within('div#limit-component') do
        select '10', from: 'limit'
      end

      assert_selector 'div#limit-component select option[selected]', text: '10'
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 10
      end

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                                      locale: @user.locale))

      within('table tbody') do
        assert_selector 'tr', count: 10
      end

      within('table thead tr') do
        assert_selector 'th', count: 10
      end
      assert_selector 'div#limit-component select option[selected]', text: '10'
    end

    test 'can sort and then filter the list of samples by name' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text '1-13 of 13'
      within('table tbody') do
        assert_selector 'tr', count: 13

        assert_text @sample1.name
        assert_no_text @sample2.name
        assert_no_text @sample9.name
      end
    end

    test 'can sort and then filter the list of samples by puid' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'
      within('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      click_button I18n.t('components.search_field_component.search_button')
      assert_selector 'input[data-test-selector="search-field-input"]', focused: true

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 1

        assert_text @sample1.name
        assert_no_text @sample2.name
        assert_no_text @sample9.name
      end
    end

    test 'should be able to toggle metadata' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_on 'Last Updated'
      assert_selector 'table thead th:nth-child(5) svg.arrow-up-icon'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 10
      end

      within('table tbody tr:first-child') do
        assert_text @sample30.name
        assert_no_selector 'td:nth-child(8)[contenteditable="true"]'
        assert_selector 'td:nth-child(8)', text: 'value1'
        assert_no_selector 'td:nth-child(9)[contenteditable="true"]'
        assert_selector 'td:nth-child(9)', text: 'value2'
        assert_selector 'td:nth-child(10)[contenteditable="true"]', text: ''
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.none')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector 'table thead tr th', count: 6
    end

    test 'can sort samples by metadata column' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 10
      end

      click_on 'metadatafield1'
      assert_selector 'table thead th:nth-child(8) svg.arrow-up-icon'

      assert_selector 'tbody tr:first-child th', text: @sample30.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample30.name

      click_on 'metadatafield2'
      assert_selector 'table thead th:nth-child(9) svg.arrow-up-icon'

      assert_selector 'tbody tr:first-child th', text: @sample30.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample30.name

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.none')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      assert_selector 'table thead th:nth-child(5) svg.arrow-down-icon'
      within('tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end
    end

    test 'filter samples with advanced search' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample9)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='puid']").select_option
            find("select[name$='[operator]']").find("option[value='in']").select_option
            find("input[name$='[value][]']").fill_in with: "#{@sample1.puid}, #{@sample2.puid}"
          end
        end
        click_button I18n.t(:'components.advanced_search_component.apply_filter_button')
      end

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
        # sample1 & sample2 found
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_no_selector "tr[id='#{dom_id(@sample9)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        click_button I18n.t(:'components.advanced_search_component.clear_filter_button')
      end

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample9)}']"
      end
    end

    test 'filter samples with advanced search using metadata fields names with extra periods' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample3)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.unique.metadata.field']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample28.metadata['unique.metadata.field']
          end
        end

        click_button I18n.t(:'components.advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        # sample28 found
        assert_no_selector "tr[id='#{dom_id(@sample1)}']"
        assert_no_selector "tr[id='#{dom_id(@sample2)}']"
        assert_no_selector "tr[id='#{dom_id(@sample3)}']"
        assert_selector "tr[id='#{dom_id(@sample28)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        click_button I18n.t(:'components.advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample3)}']"
      end
    end

    test 'filter samples with advanced search using exists operator' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample3)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        within all("fieldset[data-advanced-search-target='groupsContainer']")[0] do
          within all("fieldset[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.unique.metadata.field']").select_option
            find("select[name$='[operator]']").find("option[value='exists']").select_option
          end
        end
        click_button I18n.t(:'components.advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        # sample28 found
        assert_no_selector "tr[id='#{dom_id(@sample1)}']"
        assert_no_selector "tr[id='#{dom_id(@sample2)}']"
        assert_no_selector "tr[id='#{dom_id(@sample3)}']"
        assert_selector "tr[id='#{dom_id(@sample28)}']"
      end

      click_button I18n.t(:'components.advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
        click_button I18n.t(:'components.advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{dom_id(@sample1)}']"
        assert_selector "tr[id='#{dom_id(@sample2)}']"
        assert_selector "tr[id='#{dom_id(@sample3)}']"
      end
    end

    test 'selecting / deselecting all samples' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '25'
      end
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      click_button I18n.t(:'groups.samples.index.deselect_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
    end

    test 'selecting / deselecting a page of samples' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '20'
      end
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '19'
      end
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '20'
      end
      find('input[name="select-page"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
    end

    test 'selecting samples while filtering' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text 'Samples: 1'
      assert_selector 'table tbody tr', count: 1

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 1
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end

      click_button I18n.t(:'groups.samples.index.select_all_button')

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 1
      end
      within 'tfoot' do
        assert_text 'Samples: 1'
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: ' '
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_text 'Samples: 26'
      assert_selector 'tfoot strong[data-selection-target="selected"]', text: '0'
      assert_selector 'table tbody tr', count: 20
    end

    test 'should import metadata with disabled feature flag' do
      Flipper.disable(:metadata_import_field_selection)
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv')
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'
      ### VERIFY END ###
    end

    test 'should import metadata via csv' do
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      ### VERIFY START ###

      assert_no_selector 'dialog[open]'
    end

    test 'should not import metadata via invalid file type' do
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
        assert_no_selector '#available-list'
        assert_no_selector '#selected-list'
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
      end
    end

    test 'should import metadata with ignore empty values' do
      group = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit group_samples_url(group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/contains_empty_values_with_puid.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        assert find_field('Ignore empty values').checked?
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      visit namespace_project_sample_url(group, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within '#sample-metadata table' do
        assert_text I18n.t('projects.samples.show.table_header.key').upcase
        assert_selector 'tbody tr', count: 3
        within('tbody tr:first-child td:nth-child(2)') do
          assert_text 'metadatafield1'
        end
        within('tbody tr:first-child td:nth-child(3)') do
          assert_text 'value1'
        end
      end
      ### VERIFY END ###
    end

    test 'should import metadata without ignore empty values' do
      group = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit group_samples_url(group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/contains_empty_values_with_puid.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        uncheck 'Ignore empty values'
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'
      visit namespace_project_sample_url(group, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within '#sample-metadata table' do
        assert_text I18n.t('projects.samples.show.table_header.key').upcase
        assert_selector 'tbody tr', count: 2
        assert_no_text 'metadatafield1'
      end
      ### VERIFY END ###
    end

    test 'should not import metadata with duplicate header errors' do
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 4
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('services.spreadsheet_import.duplicate_column_names')
      end
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata row errors' do
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('services.spreadsheet_import.missing_data_row')
      end
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata column errors' do
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
      end
    end

    test 'should partially import metadata with missing sample errors' do
      visit group_samples_url(@group)

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      assert_selector '#samples-table table thead tr th', count: 10
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/mixed_project_samples_with_puid.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      assert_selector '#samples-table table thead tr th', count: 11
      ### VERIFY END ###
    end

    test 'should not import metadata with analysis values' do
      group = groups(:group_twelve)
      visit group_samples_url(group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/contains_analysis_values_with_puid.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield3'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield3'
          assert_selector 'li', count: 2
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end

      assert_no_selector 'dialog[open]'
      ### VERIFY END ###
    end

    test 'uploading spreadsheet with no viable metadata should display error' do
      group = groups(:group_twelve)
      visit group_samples_url(group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv')

        assert_text I18n.t('shared.samples.metadata.file_imports.dialog.no_valid_metadata')
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
      end
    end

    test 'should not import metadata from ignored header values' do
      visit group_samples_url(@group)

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # description and project_puid metadata headers do not exist
      within('#samples-table table thead tr') do
        assert_selector 'th', count: 10
      end
      within('#samples-table table thead') do
        assert_text 'METADATAFIELD1'
        assert_no_text 'DESCRIPTION'
        assert_no_text 'PROJECT_PUID'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_ignored_headers.csv')
        within 'ul#available-list' do
          assert_no_text 'metadatafield1'
          assert_no_text 'metadatafield2'
          assert_no_text 'metadatafield3'
          assert_no_text 'description'
          assert_no_text 'project_puid'
          assert_no_selector 'li'
        end
        within 'ul#selected-list' do
          assert_text 'metadatafield1'
          assert_text 'metadatafield2'
          assert_text 'metadatafield3'
          assert_no_text 'description'
          assert_no_text 'project_puid'
          assert_selector 'li', count: 3
        end
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::MetadataImportJob]

        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      assert_selector '#samples-table table thead tr th', count: 11
      within('#samples-table table') do
        within('thead') do
          assert_text 'METADATAFIELD3'
          assert_no_text 'DESCRIPTION'
          assert_no_text 'PROJECT_PUID'
        end
      end
      ### VERIFY END ###
    end

    test 'dialog close button is hidden during metadata import' do
      visit group_samples_url(@group)
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      within('#dialog') do
        # dialog close button available when selecting params
        assert_selector 'button.dialog--close'

        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv')
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        # dialog button hidden while importing
        assert_no_selector 'button.dialog--close'
        perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      end
      ### VERIFY END ###
    end

    test 'can update metadata value that is not from an analysis' do
      ### SETUP START ###
      visit group_samples_url(@group)

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 10
      end

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within('table tbody tr:first-child') do
        assert_selector 'td:nth-child(7)[contenteditable="true"]'
        find('td:nth-child(7)').click

        find('td:nth-child(7)').send_keys('value2')
        find('td:nth-child(7)').native.send_keys(:return)
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_selector 'td:nth-child(7)[contenteditable="true"]', text: 'value2'
      end

      assert_text I18n.t('samples.editable_cell.update_success')

      assert_no_selector 'dialog[open]'
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')
      ### VERIFY END ###
    end

    test 'project analysts should not be able to edit samples' do
      ### SETUP START ###
      login_as users(:ryan_doe)
      visit group_samples_url(@group)

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      within('table thead tr') do
        assert_selector 'th', count: 10
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample28.name
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      ### SETUP END ###

      ### VERIFY START ###
      within('table tbody tr:first-child td:nth-child(7)') do
        assert_no_selector "form[method='get']"
      end
      ### VERIFY END ###
    end

    test 'should import samples' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
        assert_no_text 'my new sample 1'
        assert_no_text 'my new sample 2'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv'))
        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

        # success msg
        assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
        click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      within('table tbody') do
        # added 2 new samples
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
        assert_selector 'tr:nth-child(2) td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
      end
      ### VERIFY END ###
    end

    test 'should import sample including missing project puid if static project selected' do
      ### SETUP START ###
      project2 = projects(:project2)
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
        assert_no_text 'my new sample 1'
        assert_no_text 'my new sample 2'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/missing_puid.csv'))

        find('input.select2-input').click
        find("li[data-value='#{project2.id}']").click

        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

        # success msg
        assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

        click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      within('table tbody') do
        # sample 2 with blank spreadsheet project puid added to static project
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAB'
        # sample 1 with valid spreadsheet project puid added to said project
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
        assert_selector 'tr:nth-child(2) td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
      end
      ### VERIFY END ###
    end

    test 'should not import sample with missing project puid if static project is not selected' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
        assert_no_text 'my new sample 1'
        assert_no_text 'my new sample 2'
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/missing_puid.csv'))

        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

        # success msg
        assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

        click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 27,
                                                                                      locale: @user.locale))
      within('table tbody') do
        # sample 1 with valid spreadsheet project puid added to said project
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample 1'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'

        # sample 2 with blank spreadsheet project puid is not added
        assert_no_text 'my new sample 2'
      end
      ### VERIFY END ###
    end

    test 'should disable select inputs if file is unselected' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        # verify initial disabled states of select inputs
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: true
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: true
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.project_puid_column'), disabled: true
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv'))

        # select inputs no longer disabled after file uploaded
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: false
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: false
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.project_puid_column'), disabled: false

        attach_file('spreadsheet_import[file]', Rails.root.join)
        # verify select inputs are re-disabled after file is unselected
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_name_column'), disabled: true
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column'), disabled: true
        assert_select I18n.t('shared.samples.spreadsheet_imports.dialog.project_puid_column'), disabled: true
        # verify blank values still exist
        assert_text I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_name_column')
        assert_text I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column')
        assert_text I18n.t('shared.samples.spreadsheet_imports.dialog.select_project_puid_column')
        ### ACTIONS AND VERIFY END ###
      end
    end

    test 'pagy overflow redirects to first page' do
      group = groups(:group_seventeen)
      sample = samples(:bulk_sample19)

      visit group_samples_url(group)

      within('#samples-table table') do
        within('tbody') do
          # rows
          assert_selector '#samples-table table tbody tr', count: 20
          # row contents
        end
      end

      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')

      assert_no_selector 'html[aria-busy="true"]'

      # verifies navigation to page
      assert_selector 'h1', text: I18n.t('groups.samples.index.title')

      # samples table
      within('#samples-table table') do
        within('tbody') do
          # rows
          assert_selector '#samples-table table tbody tr', count: 20
          # row contents
        end
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: sample.puid
      find('input[data-test-selector="search-field-input"]').native.send_keys(:return)

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # Search for PUID
      #        within('#samples-table table') do
      within('tbody') do
        # rows
        assert_selector 'tr', count: 11

        within("tr[id='#{dom_id(sample)}']") do
          assert_selector 'th:first-child', text: sample.puid
          assert_selector 'td:nth-child(2)', text: sample.name
        end
      end
    end

    test 'batch sample import metadata fields listing' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        # metadata sortable lists hidden
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_valid.csv'))
        # metadata sortable lists no longer hidden
        assert_selector 'div[data-spreadsheet-import-target="metadata"]'
        within('#Selected') do
          assert_text 'metadata1'
          assert_text 'metadata2'
        end

        # unselect description and have it appear within metadata
        select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Selected') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_text 'description'
        end

        # move all metadata to available list
        find('#metadata1').click
        find('#metadata2').click
        find('#description').click

        click_button I18n.t('components.viral.sortable_list.list_component.remove')

        within('#Available') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_text 'description'
        end

        # re-select description which removes it from metadata listing
        select 'description',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Available') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_no_text 'description'
        end

        # unselect description and have to re-added to selected listing
        select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Available') do
          assert_text 'metadata1'
          assert_text 'metadata2'
          assert_no_text 'description'
        end

        within('#Selected') do
          assert_no_text 'metadata1'
          assert_no_text 'metadata2'
          assert_text 'description'
        end
        ### ACTIONS AND VERIFY END ###
      end
    end

    test 'batch sample import metadata fields listing does not render if no metadata fields' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        # metadata sortable lists hidden
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv'))
        # metadata sortable lists still hidden
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'

        select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        # metadata sortable lists renders now that description header is available
        assert_selector 'div[data-spreadsheet-import-target="metadata"]'

        within('#Selected') do
          assert_text 'description'
        end

        select 'description',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'

        ### ACTIONS AND VERIFY END ###
      end
    end

    test 'batch sample import with partial metadata fields' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      within('#dialog') do
        assert_no_selector 'div[data-spreadsheet-import-target="metadata"]'
        attach_file('spreadsheet_import[file]',
                    Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_valid.csv'))
        assert_selector 'div[data-spreadsheet-import-target="metadata"]'

        # make metadata selections so one metadata field is in available and one is in selected
        find('#metadata1').click
        find('#metadata2').click

        click_button I18n.t('components.viral.sortable_list.list_component.remove')

        select 'metadata1',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        select 'description',
               from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

        within('#Selected') do
          assert_text 'metadata1'
        end

        within('#Available') do
          assert_text 'metadata2'
        end

        click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
        ### ACTIONS END ###
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]

        # success msg
        assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

        click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      assert_selector 'div[data-test-selector="spinner"]'
      assert_no_selector 'div[data-test-selector="spinner"]'

      # only metadata1 imported and not metadata2
      within('table thead tr') do
        assert_selector 'th', count: 11
        assert_selector 'th:nth-child(8)', text: 'METADATA1'
        assert_no_text 'METADATA2'
      end
      within('table tbody') do
        assert_selector 'tr:first-child td:nth-child(2)', text: 'my new sample 2'
        assert_selector 'tr:first-child td:nth-child(8)', text: 'c'

        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
        assert_selector 'tr:nth-child(2) td:nth-child(8)', text: 'a'
      end
    end

    test 'group without projects should not render sample actions dropdown' do
      group = groups(:group_seven)
      ### SETUP START ###
      visit group_samples_url(group)

      assert_selector 'div.empty_state_message'
      assert_text I18n.t('groups.samples.table.no_associated_samples')
      assert_text I18n.t('groups.samples.table.no_samples')

      assert_no_selector 'button', text: I18n.t(:'shared.samples.actions_dropdown.label')
    end

    test 'transfer dialog sample listing' do
      ### SETUP START ###
      samples = []
      @group.project_namespaces.map do |pn|
        samples << pn.project.samples.pluck(:name, :puid)
      end

      samples.flatten!

      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end

      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#list_selections') do
        samples.each do |sample|
          assert_text sample[0]
          assert_text sample[1]
        end
      end
      ### VERIFY END ###
    end

    test 'transfer dialog with plural description' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                                '26')
      end
      ### VERIFY END ###
    end

    test 'transfer dialog with singular description' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('samples.transfers.dialog.description.singular')
      end
      ### VERIFY END ###
    end

    test 'transfer samples' do
      ### SETUP START ###
      group_three = groups(:group_three)
      project4 = projects(:project4)
      samples = []
      @group.project_namespaces.map do |pn|
        samples << pn.project.samples.pluck(:name, :puid)
      end

      samples.flatten!

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      # target project has 3 samples prior to transfer
      visit group_samples_url(group_three)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      ### SETUP END ###

      ### ACTIONS START ###
      # select first sample
      within 'tbody' do
        first('input[name="sample_ids[]"]').click
      end
      within 'tfoot' do
        assert_text 'Samples: 26 Selected: 1'
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text samples[0][0]
          assert_text samples[0][1]
        end
        # select destination project
        find('input.select2-input').click
        find("li[data-value='#{project4.id}']").click

        click_on I18n.t('samples.transfers.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]

        # flash msg
        assert_text I18n.t('samples.transfers.create.success')
        click_button I18n.t('shared.samples.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 25,
                                                                                      locale: @user.locale))

      # destination project received transferred samples
      visit group_samples_url(group_three)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      within '#samples-table table tbody' do
        assert_text samples[0][0]
        assert_text samples[0][1]
      end
      ### VERIFY END ###
    end

    test 'dialog close button hidden during transfer samples' do
      ### SETUP START ###
      project4 = projects(:project4)
      samples = []
      @group.project_namespaces.map do |pn|
        samples << pn.project.samples.pluck(:name, :puid)
      end

      samples.flatten!
      # originating project has 3 samples prior to transfer
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select all 3 samples
      click_button I18n.t(:'groups.samples.index.select_all_button')
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector '#dialog'
      within('#dialog') do
        # close button available before confirming
        assert_selector 'button.dialog--close'
        within('#list_selections') do
          samples.each do |sample|
            # additional asserts to help prevent select2 actions below from flaking
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        # select destination project
        find('input.select2-input').click
        find("li[data-value='#{project4.id}']").click
        click_on I18n.t('samples.transfers.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        # close button hidden during transfer
        assert_no_selector 'button.dialog--close'
        perform_enqueued_jobs only: [::Samples::TransferJob]
      end
      ### VERIFY END ###
    end

    test 'should not transfer samples with session storage cleared' do
      ### SETUP START ###
      project4 = projects(:project4)
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      # launch transfer dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('samples.transfers.dialog.title')
        find('input.select2-input').click
        find("li[data-value='#{project4.id}']").click
        click_on I18n.t('samples.transfers.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]

        # samples listing should no longer appear in dialog
        assert_no_selector '#list_selections'
        # error msg displayed in dialog
        assert_text I18n.t('samples.transfers.create.no_samples_transferred_error')
      end
      ### VERIFY END ###
    end

    test 'transfer samples with and without same name in destination project' do
      # only samples without a matching name to samples in destination project will transfer

      ### SETUP START ###
      group_three = groups(:group_three)
      project4 = projects(:project4)
      samples = []
      @group.project_namespaces.map do |pn|
        samples << pn.project.samples.pluck(:name, :puid)
      end

      sample1 = samples(:sample1)
      sample2 = samples(:sample2)
      sample28 = samples(:sample28)
      sample30 = samples(:sample30)

      samples.flatten!

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      # target project has 3 samples prior to transfer
      visit group_samples_url(group_three)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          samples.each do |sample|
            # additional asserts to help prevent select2 actions below from flaking
            assert_text sample[0]
            assert_text sample[1]
          end
        end
        find('input.select2-input').click
        find("li[data-value='#{project4.id}']").click
        click_on I18n.t('samples.transfers.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::TransferJob]

        # error messages in dialog
        assert_text I18n.t('samples.transfers.create.error')

        assert_text I18n.t('services.samples.transfer.unauthorized', sample_ids: sample28.id.to_s).gsub(':', '')

        # colon is removed from translation in UI
        assert_text I18n.t('services.samples.transfer.sample_exists', sample_puid: sample30.puid,
                                                                      sample_name: sample30.name).gsub(':', '')

        click_button I18n.t('shared.samples.errors.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # verify sample1 and 2 transferred, sample 28, sample 30 did not
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))
      assert_no_selector "tr[id='#{dom_id(sample1)}']"
      assert_no_selector "tr[id='#{dom_id(sample2)}']"
      assert_selector "tr[id='#{dom_id(sample30)}']"
      assert_selector "tr[id='#{dom_id(sample28)}']"

      # destination project
      visit group_samples_url(group_three)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 25,
                                                                                      locale: @user.locale))

      click_on I18n.t(:'samples.table_component.puid')

      assert_selector "tr[id='#{dom_id(sample1)}']"
      assert_selector "tr[id='#{dom_id(sample2)}']"
      assert_no_selector "tr[id='#{dom_id(sample28)}']"
      assert_no_selector "tr[id='#{dom_id(sample30)}']"
      ### VERIFY END ###
    end

    test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
      ### SETUP START ###
      login_as users(:micha_doe)
      group_three = groups(:group_three)
      group_three_proj_namespaces = group_three.project_namespaces
      total_projects_transfer_to_count = 0
      group_three_projects = group_three_proj_namespaces.map(&:project)

      visit group_samples_url(group_three)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        # Only projects within group are visible for maintainer to transfer to
        find('input.select2-input').click
        group_three_projects.each do |proj|
          total_projects_transfer_to_count += 1 if find("li[data-value='#{proj.id}']")
        end

        assert_equal total_projects_transfer_to_count, group_three_projects.count
      end
      ### VERIFY END ###
    end

    test 'empty state of transfer sample project selection' do
      ### SETUP START ###
      group_three = groups(:group_three)
      visit group_samples_url(group_three)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 3
      end
      within 'tfoot' do
        assert_text 'Samples: 3'
        assert_selector 'strong[data-selection-target="selected"]', text: '3'
      end

      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector '#dialog'
      within('#dialog') do
        # fill destination input
        find('input.select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('samples.transfers.dialog.empty_state')
        ### VERIFY END ###
      end
    end

    test 'singular clone dialog description' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t('samples.clones.dialog.description.singular')
      end
      ### VERIFY END ###
    end

    test 'plural clone dialog description' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#dialog') do
        assert_text I18n.t(
          'samples.clones.dialog.description.plural'
        ).gsub! 'COUNT_PLACEHOLDER', '26'
      end
      ### VERIFY END ###
    end

    test 'clone dialog sample listing' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within '#samples-table table tbody' do
        find("input##{dom_id(@sample1, :checkbox)}").click
        find("input##{dom_id(@sample2, :checkbox)}").click
      end
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 2
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '2'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      within('#list_selections') do
        assert_text @sample1.name
        assert_text @sample1.puid
        assert_text @sample2.name
        assert_text @sample2.puid
      end
      ### VERIFY END ###
    end

    test 'should clone samples' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      within '#samples-table table tbody' do
        find("input##{dom_id(@sample1, :checkbox)}").click
        find("input##{dom_id(@sample2, :checkbox)}").click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
          assert_text @sample2.name
          assert_text @sample2.puid
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]

        # flash msg
        assert_text I18n.t('samples.clones.create.success')
        click_button I18n.t('shared.samples.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # samples table now contains both original and cloned samples
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      # duplicated sample names
      within('#samples-table table tbody') do
        assert_text @sample1.name, count: 2
        assert_text @sample2.name, count: 2
      end

      # samples now exist in project2 samples table
      visit namespace_project_samples_url(@group, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 22,
                                                                                      locale: @user.locale))
      within('#samples-table table tbody') do
        assert_text @sample1.name
        assert_text @sample2.name
      end
      ### VERIFY END ###
    end

    test 'dialog close button hidden while cloning samples' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples 1 and 2 for cloning
      within '#samples-table table tbody' do
        find("input##{dom_id(@sample1, :checkbox)}").click
        find("input##{dom_id(@sample2, :checkbox)}").click
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        # close button available before confirming cloning
        assert_selector 'button.dialog--close'
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
          assert_text @sample2.name
          assert_text @sample2.puid
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')
        # close button hidden during cloning
        assert_no_selector 'button.dialog--close'
        perform_enqueued_jobs only: [::Samples::CloneJob]
      end
      ### VERIFY END ###
    end

    test 'should not clone samples with session storage cleared' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('samples.clones.dialog.title')
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]

        # sample listing should not be in error dialog
        assert_no_selector '#list_selections'
        # error msg
        assert_text I18n.t('samples.clones.create.no_samples_cloned_error')
        assert_text I18n.t('services.samples.clone.empty_sample_ids')
      end
      ### VERIFY END ###
    end

    test 'should not clone some samples' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          assert_text @sample1.name
          assert_text @sample2.name
        end
        find('input.select2-input').click
        find("li[data-value='#{@project1.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
      end

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]

        # errors that a sample with the same name as sample30 already exists in project25
        assert_text I18n.t('samples.clones.create.error')
        assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample1.puid,
                                                                   sample_name: @sample1.name).gsub(':', '')
        assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample2.puid,
                                                                   sample_name: @sample2.name).gsub(':', '')
        click_on I18n.t('shared.samples.errors.ok_button')
      end

      # verify dialog is closed
      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # verify samples table updates with cloned samples
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 47,
                                                                                      locale: @user.locale))
      ### VERIFY END ###
    end

    test 'empty state of destination project selection for sample cloning' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ####
      click_button I18n.t(:'groups.samples.index.select_all_button')
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector '#dialog'
      within('#dialog') do
        find('input.select2-input').fill_in with: 'invalid project name or puid'
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_text I18n.t('samples.clones.dialog.empty_state')
        ### VERIFY END ###
      end
    end

    test 'updating sample selection during sample cloning' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select 1 sample to clone
      within '#samples-table table tbody' do
        all('input[type="checkbox"]')[0].click
      end

      # verify 1 sample selected in originating project
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 26"
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end

      # clone sample
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector '#dialog'
      within('#dialog') do
        within('#list_selections') do
          # additional asserts to help prevent select2 actions below from flaking
          assert_text @sample1.name
          assert_text @sample1.puid
        end
        find('input.select2-input').click
        find("li[data-value='#{@project2.id}']").click
        click_on I18n.t('samples.clones.dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.progress_bar.in_progress')

        perform_enqueued_jobs only: [::Samples::CloneJob]

        # flash msg
        assert_text I18n.t('samples.clones.create.success')
        click_button I18n.t('shared.samples.success.ok_button')
      end

      assert_no_selector 'dialog[open]'

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # verify no samples selected anymore
      within 'tfoot' do
        assert_text "#{I18n.t('samples.table_component.counts.samples')}: 27"
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      ### VERIFY END ###
    end

    test 'delete samples belonging to group' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.delete_samples')
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples for deletion
      within '#samples-table table tbody' do
        find("input##{dom_id(@sample1,
                             :checkbox)}").click
        find("input##{dom_id(@sample2,
                             :checkbox)}").click
      end
      # click delete samples button
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      # verify dialog contents
      within '#multiple-deletions-dialog' do
        assert_selector 'h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
        within '#list_selections' do
          assert_text @sample1.name
          assert_text @sample1.puid
          assert_text @sample2.name
          assert_text @sample2.name
        end
        # submit
        click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.deletions.destroy.success', count: 2)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 24,
                                                                                      locale: @user.locale))
      ### VERIFY END ###
    end

    test 'delete group samples with partial success' do
      sample25 = samples(:sample25)
      sample28 = samples(:sample28)
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.delete_samples')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples for deletion
      within '#samples-table table tbody' do
        find("input##{dom_id(sample25,
                             :checkbox)}").click
        find("input##{dom_id(sample28,
                             :checkbox)}").click
      end
      # click delete samples button
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      # verify dialog contents
      within '#multiple-deletions-dialog' do
        assert_selector 'h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
        within '#list_selections' do
          assert_text sample25.name
          assert_text sample25.puid
          assert_text sample28.name
          assert_text sample28.puid
        end
        # submit
        click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.deletions.destroy.partial_success', deleted: '1/2')
      assert_text I18n.t('samples.deletions.destroy.partial_error', not_deleted: '1/2')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 25,
                                                                                      locale: @user.locale))
      ### VERIFY END ###
    end

    test 'delete group samples unsuccessfully' do
      sample28 = samples(:sample28)
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      click_button I18n.t('shared.samples.actions_dropdown.label')
      assert_selector 'button[disabled]', text: I18n.t('shared.samples.actions_dropdown.delete_samples')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples for deletion
      within '#samples-table table tbody' do
        find("input##{dom_id(sample28,
                             :checkbox)}").click
      end
      # click delete samples button
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      # verify dialog contents
      within '#multiple-deletions-dialog' do
        assert_selector 'h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
        within '#list_selections' do
          assert_text sample28.name
          assert_text sample28.puid
        end
        # submit
        click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.deletions.destroy.no_deleted_samples', deleted: '1/2')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### VERIFY END ###
    end
  end
end
