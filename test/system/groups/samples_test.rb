# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    def setup
      Flipper.enable(:advanced_search_with_auto_complete)
      Flipper.enable(:virtualized_samples_table)

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
    end

    def retrieve_puids
      (1..4).map do |n|
        first("table tbody tr:nth-child(#{n}) th").text
      end
    end

    def pluck_sample_names_and_puids(namespaces)
      samples = namespaces.map do |namespace|
        namespace.project.samples.pluck(:name, :puid)
      end
      samples.flatten!
    end

    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      assert_selector "table tbody tr[id='#{dom_id(@sample3)}'] td:nth-child(2)", text: @sample3.name
      assert_selector 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'span.cursor-not-allowed',
                      text: I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 6
      assert_no_selector "table tbody tr[id='#{dom_id(@sample3)}']"

      click_on I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
    end

    test 'visiting the index of a group which has other groups/projects linked to it' do
      login_as users(:david_doe)
      # group_one shared with group
      group = groups(:david_doe_group_four)
      visit group_samples_url(group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(2)", text: @sample1.name
      assert_selector "table tbody tr[id='#{dom_id(@sample3)}'] td:nth-child(2)", text: @sample3.name

      assert_selector 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'span.cursor-not-allowed',
                      text: I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 6
      assert_no_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "table tbody tr[id='#{dom_id(@sample3)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample28)}'] td:nth-child(2)", text: @sample28.name

      click_on I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20

      click_link @sample1.name
      assert_selector 'h1', text: @sample1.name

      visit group_samples_url(group)

      assert_selector 'a', text: I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'span.cursor-not-allowed',
                      text: I18n.t(:'components.viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'components.viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                                      locale: @user.locale))

      click_link @sample28.name
      assert_selector 'h1', text: @sample28.name
    end

    test 'visit sample show page by clicking sample name from index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_link @sample3.name
      assert_selector 'h1', text: @sample3.name
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

      assert_selector 'table tbody tr', count: 20

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(2)", text: @sample1.name
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(2)", text: @sample2.name

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text 'Samples: 13'
      assert_selector 'table tbody tr', count: 13

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(2)", text: @sample1.name
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"
    end

    test 'can sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      # Because PUIDs are not always generated the same, issues regarding order have occurred when hard testing
      # the expected ordering of samples based on PUID. To resolve this, we will gather the first 4 PUIDs and ensure
      # they are ordered as expected against one another.
      assert_selector 'table tbody tr', count: 20

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
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'
      assert_selector 'table tbody tr:nth-child(3) th', text: @sample28.puid
      assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: @sample28.name
      assert_selector 'table tbody tr:nth-child(4) th', text: @sample25.puid
      assert_selector 'table tbody tr:nth-child(4) td:nth-child(2)', text: @sample25.name

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-down-icon'
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name
    end

    test 'can filter by name and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 20
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(2)", text: @sample1.name
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] td:nth-child(2)", text: @sample2.name

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text 'Samples: 13'

      assert_selector 'table tbody tr', count: 13

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] td:nth-child(2)", text: @sample1.name
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"

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

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] th:first-child", text: @sample1.puid
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] th:first-child", text: @sample2.puid

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 1
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] th:first-child", text: @sample1.puid
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] th:first-child", text: @sample1.puid
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"
    end

    test 'can change pagination and then filter by puid' do
      visit group_samples_url(@group)

      select '10', from: 'limit'

      assert_selector 'div#limit-component select option[selected]', text: '10'
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 10
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] th:first-child", text: @sample1.puid
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}'] th:first-child", text: @sample2.puid

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 1
      assert_selector "table tbody tr[id='#{dom_id(@sample1)}'] th:first-child", text: @sample1.puid
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector 'div#limit-component select option[selected]', text: '10'
    end

    test 'can change pagination and then toggle metadata' do
      visit group_samples_url(@group)

      select '10', from: 'limit'

      assert_selector 'div#limit-component select option[selected]', text: '10'
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 10

      assert_selector 'table thead tr th', count: 6

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 10
      assert_selector 'table thead tr th', count: 10
      assert_selector 'div#limit-component select option[selected]', text: '10'
    end

    test 'can sort and then filter the list of samples by name' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 20

      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'

      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'
      assert_selector 'table tbody tr:nth-child(3) th', text: @sample28.puid
      assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: @sample28.name
      assert_selector 'table tbody tr:nth-child(4) th', text: @sample25.puid
      assert_selector 'table tbody tr:nth-child(4) td:nth-child(2)', text: @sample25.name

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 13, count: 13,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 13

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample25)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample28)}']"
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"
    end

    test 'can sort and then filter the list of samples by puid' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 20

      assert_selector 'table tbody tr:first-child th', text: @sample1.puid

      click_on I18n.t(:'samples.table_component.name')
      assert_selector 'table thead th:nth-child(2) svg.arrow-up-icon'
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.arrow-up-icon'
      assert_selector 'table tbody tr:nth-child(3) th', text: @sample28.puid
      assert_selector 'table tbody tr:nth-child(3) td:nth-child(2)', text: @sample28.name
      assert_selector 'table tbody tr:nth-child(4) th', text: @sample25.puid
      assert_selector 'table tbody tr:nth-child(4) td:nth-child(2)', text: @sample25.name

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      click_button I18n.t('common.controls.search')
      assert_selector 'input[data-test-selector="search-field-input"]', focused: true

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 1

      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_no_selector "table tbody tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "table tbody tr[id='#{dom_id(@sample9)}']"
    end

    test 'should be able to toggle metadata' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table thead tr th', count: 6

      click_on 'Last Updated'
      assert_selector 'table thead th:nth-child(5) svg.arrow-up-icon'

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

assert_selector 'table thead tr th', count: 10

      within('table tbody tr:first-child') do
        assert_text @sample30.name
        assert_no_selector 'td:nth-child(8)[data-editable="true"]'
        assert_selector 'td:nth-child(8)', text: 'value1'
        assert_no_selector 'td:nth-child(9)[data-editable="true"]'
        assert_selector 'td:nth-child(9)', text: 'value2'
        assert_selector 'td:nth-child(10)[data-editable="true"]', text: ''
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.none')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table thead tr th', count: 6
    end

    test 'can sort samples by metadata column' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table thead tr th', count: 6

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table thead tr th', count: 10

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

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table thead tr th', count: 6

      assert_selector 'table thead th:nth-child(5) svg.arrow-down-icon'

      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
      assert_selector 'table tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name
    end

    test 'filter samples with advanced search' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample9)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      find("input[role='combobox']").send_keys('Sample PUID', :enter)
      select 'in', from: 'q[groups_attributes][0][conditions_attributes][0][operator]'
      find("input[name$='[value][]']").fill_in with: "#{@sample1.puid}, #{@sample2.puid}"

      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      assert_selector '#samples-table table tbody tr', count: 2
      # sample1 & sample2 found
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample9)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      assert_selector "table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "table tbody tr[id='#{dom_id(@sample9)}']"
    end

    test 'filter samples with advanced search and autocomplete disabled' do
      Flipper.disable(:advanced_search_with_auto_complete)

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample9)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      find("select[name$='[field]']").find("option[value='puid']").select_option
      select 'in', from: 'q[groups_attributes][0][conditions_attributes][0][operator]'
      find("input[name$='[value][]']").fill_in with: "#{@sample1.puid}, #{@sample2.puid}"
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      assert_selector '#samples-table table tbody tr', count: 2
      # sample1 & sample2 found
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample9)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector "button[aria-label='#{I18n.t(:'components.advanced_search_component.title')}']", focused: true

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample9)}']"
    end

    test 'filter samples with advanced search using metadata fields names with extra periods' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample3)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      find("input[role='combobox']").send_keys('unique.metadata.field', :enter)
      select '=', from: 'q[groups_attributes][0][conditions_attributes][0][operator]'
      find("input[name$='[value]']").fill_in with: @sample28.metadata['unique.metadata.field']

      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector '#samples-table table tbody tr', count: 1
      # sample28 found
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample3)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample28)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample3)}']"
    end

    test 'filter samples with advanced search using exists operator' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample3)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      find("input[role='combobox']").send_keys('unique.metadata.field', :enter)
      select 'exists', from: 'q[groups_attributes][0][conditions_attributes][0][operator]'
      click_button I18n.t(:'components.advanced_search_component.apply_filter_button')

      assert_selector '#samples-table table tbody tr', count: 1
      # sample28 found
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_no_selector "#samples-table table tbody tr[id='#{dom_id(@sample3)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample28)}']"

      click_button I18n.t(:'components.advanced_search_component.title')
      assert_selector 'h1', text: I18n.t(:'components.advanced_search_component.title')
      click_button I18n.t(:'components.advanced_search_component.clear_filter_button')

      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample1)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample2)}']"
      assert_selector "#samples-table table tbody tr[id='#{dom_id(@sample3)}']"
    end

    test 'selecting / deselecting all samples' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 0

      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '0'

      click_button I18n.t('common.controls.select_all')

      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20

      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      uncheck "checkbox_sample_#{@sample1.id}"
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '25'

      click_button I18n.t('common.controls.select_all')

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20

      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('common.controls.deselect_all')

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 0
    end

    test 'selecting / deselecting a page of samples' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 0

      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '0'

      check 'select-page'

      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20

      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '20'

      uncheck "checkbox_sample_#{@sample1.id}"

      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '19'

      check 'select-page'

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20

      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '20'

      uncheck 'select-page'

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 0
    end

    test 'selecting samples while filtering' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 20
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 0

      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '0'

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table tfoot', text: 'Samples: 1'
      assert_selector 'table tbody tr', count: 1

      assert_selector 'table tbody input[name="sample_ids[]"]', count: 1
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 0

      click_button I18n.t('common.controls.select_all')

      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 1
      assert_selector 'table tfoot', text: 'Samples: 1'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '1'

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: ' '
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'tfoot strong[data-selection-target="selected"]', text: '0'
      assert_selector 'table tbody tr', count: 20
    end

    test 'should import metadata via csv' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv')
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield1'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield2'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield3'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'

      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      ### VERIFY END ###
    end

    test 'should not import metadata via invalid file type' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
      assert_no_selector '#available-list'
      assert_no_selector '#selected-list'
      assert_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button'), disabled: true
    end

    test 'should import metadata with ignore empty values' do
      group = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit group_samples_url(group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]',
                  Rails.root.join('test/fixtures/files/metadata/contains_empty_values_with_puid.csv')

      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield1'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield2'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield3'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'

      check 'file_import_ignore_empty_values'
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')

      visit namespace_project_sample_url(group, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      assert_selector 'div#sample-metadata'
      assert_selector 'table tbody tr', count: 3
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'metadatafield1'
      assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'value1'
      ### VERIFY END ###
    end

    test 'should import metadata without ignore empty values' do
      group = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit group_samples_url(group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]',
                  Rails.root.join('test/fixtures/files/metadata/contains_empty_values_with_puid.csv')

      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield1'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield2'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield3'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'
      uncheck 'Ignore empty values'
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      visit namespace_project_sample_url(group, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')

      assert_selector 'div#sample-metadata'
      assert_selector 'table tbody tr', count: 2
      assert_no_text 'metadatafield1'
      ### VERIFY END ###
    end

    test 'should not import metadata with duplicate header errors' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')

      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield1'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield2'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield3'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'
      assert_selector 'ul#selected-list li', count: 4
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('services.spreadsheet_import.duplicate_column_names')
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata row errors' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')

      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')

      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield1'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield2'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield3'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'
      assert_selector 'ul#selected-list li', count: 3
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('services.spreadsheet_import.missing_data_row')
      ### VERIFY END ###
    end

    test 'should not import metadata with missing metadata column errors' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')

      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.no_valid_metadata')
      assert_button I18n.t('shared.samples.metadata.file_imports.dialog.submit_button'), disabled: true
    end

    test 'should partially import metadata with missing sample errors' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector '#samples-table table thead tr th', count: 10
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]',
                  Rails.root.join('test/fixtures/files/metadata/mixed_project_samples_with_puid.csv')

      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield1'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield2'
      assert_no_selector 'ul#available-list li', exact_text: 'metadatafield3'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'
      assert_selector 'ul#selected-list li', count: 3
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
      click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'
      assert_selector '#samples-table table thead tr th', count: 11
      ### VERIFY END ###
    end

    test 'should not import metadata with analysis values' do
      group = groups(:group_twelve)
      visit group_samples_url(group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector '#samples-table table thead tr th', count: 8
      assert_selector '#samples-table table tbody tr:last-child td:nth-child(7)', text: 'value1'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]',
                  Rails.root.join('test/fixtures/files/metadata/contains_analysis_values_with_puid.csv')

      assert_no_selector 'ul#available-list li'

      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'
      assert_selector 'ul#selected-list li', count: 2
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
      click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_no_selector '#samples-table table tbody tr:last-child td:nth-child(7)', text: '10'
      assert_selector '#samples-table table tbody tr:last-child td:nth-child(7)', text: 'value1'
      ### VERIFY END ###
    end

    test 'should not import metadata from ignored header values' do
      visit group_samples_url(@group)

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      # description and project_puid metadata headers do not exist
      assert_selector '#samples-table table thead tr th', count: 10
      assert_selector '#samples-table table thead th', exact_text: 'METADATAFIELD1'
      assert_no_selector '#samples-table table thead th', exact_text: 'METADATAFIELD3'
      assert_no_selector '#samples-table table thead th', exact_text: 'DESCRIPTION'
      assert_no_selector '#samples-table table thead th', exact_text: 'PROJECT_PUID'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/contains_ignored_headers.csv')

      assert_no_selector 'ul#available-list li'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield1'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield2'
      assert_selector 'ul#selected-list li', exact_text: 'metadatafield3'
      assert_selector 'ul#selected-list li', count: 3
      assert_no_selector 'li', exact_text: 'description'
      assert_no_selector 'li', exact_text: 'project_puid'
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1

      assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
      click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      assert_selector '#samples-table table thead tr th', count: 11
      assert_selector '#samples-table table thead th', exact_text: 'METADATAFIELD3'
      assert_no_selector '#samples-table table thead th', exact_text: 'DESCRIPTION'
      assert_no_selector '#samples-table table thead th', exact_text: 'PROJECT_PUID'
      ### VERIFY END ###
    end

    test 'verify metadata columns are hidden and unhidden during file selection' do
      ### SETUP START ###
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      # find metadataColumns div container
      metadata_columns_element = find('div[data-metadata--file-import-target="metadataColumns"]', visible: :all)
      # verify by default it's hidden and has aria-hidden="true"
      assert_equal 'true', metadata_columns_element['aria-hidden']
      assert_no_selector 'div[data-metadata--file-import-target="metadataColumns"]'

      # verify after uploading file, metadata columns are shown and aria-hidden is removed
      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid.xlsx')
      assert_not metadata_columns_element['aria-hidden']
      assert_selector 'div[data-metadata--file-import-target="metadataColumns"]'

      # remove file and verify metadataColumns is hidden and aria-hidden="true" is re-added
      attach_file 'file_import[file]', nil
      assert_equal 'true', metadata_columns_element['aria-hidden']
      assert_no_selector 'div[data-metadata--file-import-target="metadataColumns"]'
      ### ACTIONS AND VERIFY END ###
    end

    test 'dialog close button is hidden during metadata import' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_metadata')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      # dialog close button available when selecting params
      assert_selector 'button.dialog--close'

      attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv')
      click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.metadata.file_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      # dialog button hidden while importing
      assert_no_selector 'button.dialog--close'
      perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      assert_performed_jobs 1
      ### VERIFY END ###
    end

    test 'can update metadata value that is not from an analysis' do
      ### SETUP START ###
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table thead tr th', count: 6

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table thead tr th', count: 10

      within '.table-container' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      ### ACTIONS START ###
within('table tbody tr:first-child') do
        assert_selector 'td:nth-child(7)[data-editable="true"]'
        find('td:nth-child(7)').click
        find('td:nth-child(7)').native.send_keys(:return) # Activate edit mode with Enter

        find('td:nth-child(7)').send_keys('value2')
        find('td:nth-child(7)').send_keys(:return)
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_selector 'td:nth-child(7)', text: 'value2'
      end

      assert_text I18n.t('samples.editable_cell.update_success')

      assert_no_selector 'dialog[open]'
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.confirm_button')
      assert_no_selector 'dialog button',
                         text: I18n.t('shared.samples.metadata.editing_field_cell.dialog.discard_button')

      # Regression: ensure the same cell remains editable after the Turbo Stream update
      within('table tbody tr:first-child') do
        assert_selector 'td:nth-child(7)[aria-colindex="7"]'
        assert_selector 'td:nth-child(7)[data-editable="true"]', text: 'value2'
        find('td:nth-child(7)').click
        find('td:nth-child(7)').native.send_keys(:return)

        find('td:nth-child(7)').send_keys('value3')
        find('td:nth-child(7)').native.send_keys(:return)

        assert_selector 'td:nth-child(7)', text: 'value3'
      end
      ### VERIFY END ###
    end

    test 'project analysts should not be able to edit samples' do
      ### SETUP START ###
      login_as users(:ryan_doe)
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector 'table thead tr th', count: 10

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample28.name
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      ### SETUP END ###

      ### VERIFY START ###
      assert_no_selector "table tbody tr:first-child td:nth-child(7) form[method='get']"
      ### VERIFY END ###
    end

    test 'should import samples' do
      ### SETUP START ###
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 20
      assert_selector 'td', exact_text: 'Project 1 Sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 2'
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv'))
      click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
      click_button I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))

      # added 2 new samples
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
      ### VERIFY END ###
    end

    test 'should import sample including missing project puid if static project selected' do
      ### SETUP START ###
      project2 = projects(:project2)
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      assert_selector 'table tbody tr', count: 20
      assert_selector 'td', exact_text: 'Project 1 Sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 2'
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/missing_puid.csv'))
      find('input.select2-input').click
      find("li[data-value='#{project2.id}']").click

      click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))

      # sample 2 with blank spreadsheet project puid added to static project
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAB'
      # sample 1 with valid spreadsheet project puid added to said project
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
      ### VERIFY END ###
    end

    test 'should not import sample with missing project puid if static project is not selected' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      assert_selector 'td', exact_text: 'Project 1 Sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 2'
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/missing_puid.csv'))

      click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 27,
                                                                                      locale: @user.locale))

      # sample 1 with valid spreadsheet project puid added to said project
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 1'
      assert_selector 'table tbody tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'

      # sample 2 with blank spreadsheet project puid is not added
      assert_no_selector 'td', exact_text: 'my new sample 2'
      ### VERIFY END ###
    end

    test 'should import samples with metadata that have whitespaces' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      assert_selector 'td', exact_text: 'Project 1 Sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 1'
      assert_no_selector 'td', exact_text: 'my new sample 2'

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector '#samples-table table thead tr th', count: 10
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/valid_with_whitespaces.csv'))

      assert_no_selector 'ul#available-list li'

      assert_selector 'ul#selected-list li', exact_text: 'metadata field 1'
      assert_selector 'ul#selected-list li', exact_text: 'metadata field 2'
      assert_selector 'ul#selected-list li', exact_text: 'metadata field 3'
      assert_selector 'ul#selected-list li', count: 3

      # click on "metadata field 1" and then remove it
      find('li', exact_text: 'metadata field 1').click

      click_button I18n.t('common.actions.remove')

      # verify only "metadata field 1" was removed

      assert_selector 'ul#available-list li', exact_text: 'metadata field 1'
      assert_selector 'ul#available-list li', count: 1

      assert_no_selector 'ul#selected-list li', exact_text: 'metadata field 1'
      assert_selector 'ul#selected-list li', exact_text: 'metadata field 2'
      assert_selector 'ul#selected-list li', exact_text: 'metadata field 3'
      assert_selector 'ul#selected-list li', count: 2

      click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')
      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      # 2 new metadata fields added
      assert_selector '#samples-table table thead tr th',
                      count: 12
      # added 2 new samples
      assert_selector '#samples-table table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector '#samples-table table tbody tr:first-child td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'
      assert_selector '#samples-table table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      assert_selector '#samples-table table tbody tr:nth-child(2) td:nth-child(3)', text: 'INXT_PRJ_AAAAAAAAAA'

      # verify metadata fields 2 and 3 added, not 1
      assert_selector 'th', exact_text: 'METADATA FIELD 2'
      assert_selector 'th', exact_text: 'METADATA FIELD 3'
      assert_no_text 'METADATA FIELD 1'
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
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
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

    test 'pagy overflow redirects to first page' do
      group = groups(:group_seventeen)
      sample = samples(:bulk_sample19)

      visit group_samples_url(group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 200,
                                                                                      locale: @user.locale))
      # rows
      assert_selector '#samples-table table tbody tr', count: 20

      assert_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.next')
      assert_no_link exact_text: I18n.t(:'components.viral.pagy.pagination_component.previous')

      click_on I18n.t(:'components.viral.pagy.pagination_component.next')

      assert_no_selector 'html[aria-busy="true"]'

      # verifies navigation to page
      assert_selector 'h1', text: I18n.t('groups.samples.index.title')

      # rows
      assert_selector '#samples-table table tbody tr', count: 20

      # Search for PUID
      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: sample.puid
      find('input[data-test-selector="search-field-input"]').send_keys(:return)

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      assert_selector '#samples-table table tbody tr', count: 11
      assert_selector '#samples-table table tbody tr:first-child th:first-child', text: sample.puid
      assert_selector '#samples-table table tbody tr:first-child td:nth-child(2)', text: sample.name
    end

    test 'batch sample import metadata fields listing' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      # metadata sortable lists hidden
      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_valid.csv'))
      # metadata sortable lists no longer hidden
      assert_selector 'ul#available-list'
      assert_selector 'ul#selected-list'

      assert_no_selector 'ul#available-list li'
      assert_selector 'ul#selected-list li', exact_text: 'metadata1'
      assert_selector 'ul#selected-list li', exact_text: 'metadata2'
      assert_selector 'ul#selected-list li', count: 2

      # unselect description and have it appear within metadata
      select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_no_selector 'ul#available-list li'
      assert_selector 'ul#selected-list li', exact_text: 'metadata1'
      assert_selector 'ul#selected-list li', exact_text: 'metadata2'
      assert_selector 'ul#selected-list li', exact_text: 'description'
      assert_selector 'ul#selected-list li', count: 3

      # move all metadata to available list
      find('li', exact_text: 'metadata1').click
      find('li', exact_text: 'metadata2').click
      find('li', exact_text: 'description').click

      click_button I18n.t('common.actions.remove')

      assert_no_selector 'ul#selected-list li'
      assert_selector 'ul#available-list li', exact_text: 'metadata1'
      assert_selector 'ul#available-list li', exact_text: 'metadata2'
      assert_selector 'ul#available-list li', exact_text: 'description'
      assert_selector 'ul#available-list li', count: 3

      # re-select description which removes it from metadata listing
      select 'description',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_no_selector 'ul#selected-list li'
      assert_selector 'ul#available-list li', exact_text: 'metadata1'
      assert_selector 'ul#available-list li', exact_text: 'metadata2'
      assert_no_selector 'ul#available-list li', exact_text: 'description'
      assert_selector 'ul#available-list li', count: 2
      # unselect description and have to re-added to selected listing
      select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_selector 'ul#selected-list li', exact_text: 'description'
      assert_selector 'ul#selected-list li', count: 1
      assert_selector 'ul#available-list li', exact_text: 'metadata1'
      assert_selector 'ul#available-list li', exact_text: 'metadata2'
      assert_selector 'ul#available-list li', count: 2
      ### ACTIONS AND VERIFY END ###
    end

    test 'batch sample import metadata fields listing does not render if no metadata fields' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      ### SETUP END ###

      ### ACTIONS AND VERIFY START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      # metadata sortable lists hidden
      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv'))
      # metadata sortable lists still hidden
      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'

      select I18n.t('shared.samples.spreadsheet_imports.dialog.select_sample_description_column'),
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      # metadata sortable lists renders now that description header is available
      assert_selector 'ul#available-list'
      assert_selector 'ul#selected-list'

      assert_selector 'ul#selected-list li', exact_text: 'description'
      assert_selector 'ul#selected-list li', count: 1

      select 'description',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'
      ### ACTIONS AND VERIFY END ###
    end

    test 'batch sample import with partial metadata fields' do
      ### SETUP START ###
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      ### SETUP END ###

      ### ACTIONS START ###
      # start import
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.import_samples')
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_no_selector 'ul#available-list'
      assert_no_selector 'ul#selected-list'
      attach_file('spreadsheet_import[file]',
                  Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_valid.csv'))
      assert_selector 'ul#available-list'
      assert_selector 'ul#selected-list'

      assert_no_selector 'ul#available-list li'
      assert_selector 'ul#selected-list li', exact_text: 'metadata1'
      assert_selector 'ul#selected-list li', exact_text: 'metadata2'
      assert_selector 'ul#selected-list li', count: 2
      # make metadata selections so one metadata field is in available and one is in selected
      find('li', exact_text: 'metadata1').click
      find('li', exact_text: 'metadata2').click

      click_button I18n.t('common.actions.remove')

      assert_no_selector 'ul#selected-list li'
      assert_selector 'ul#available-list li', exact_text: 'metadata1'
      assert_selector 'ul#available-list li', exact_text: 'metadata2'
      assert_selector 'ul#available-list li', count: 2

      select 'metadata1',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      select 'description',
             from: I18n.t('shared.samples.spreadsheet_imports.dialog.sample_description_column')

      assert_selector 'ul#selected-list li', exact_text: 'metadata1'
      assert_selector 'ul#selected-list li', count: 1
      assert_selector 'ul#available-list li', exact_text: 'metadata2'
      assert_selector 'ul#available-list li', count: 1
      click_on I18n.t('shared.samples.spreadsheet_imports.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      perform_enqueued_jobs only: [::Samples::BatchSampleImportJob]
      assert_performed_jobs 1

      # success msg
      assert_text I18n.t('shared.samples.spreadsheet_imports.success.description')

      click_on I18n.t('shared.samples.spreadsheet_imports.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('shared.samples.spreadsheet_imports.dialog.title')

      # refresh to see new samples
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      assert_selector 'table thead tr th', count: 6

      click_button I18n.t('shared.samples.metadata_templates.label')
      click_button I18n.t('shared.samples.metadata_templates.fields.all')

      if has_selector?('div[data-test-selector="spinner"]', wait: 0.25.seconds)
        assert_no_selector 'div[data-test-selector="spinner"]'
      end

      # only metadata1 imported and not metadata2
      assert_selector 'table thead tr th', count: 11
      assert_selector 'table thead tr th:nth-child(8)', text: 'METADATA1'
      assert_no_selector 'tr', exact_text: 'METADATA2'

      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: 'my new sample 2'
      assert_selector 'table tbody tr:first-child td:nth-child(8)', text: 'c'

      assert_selector 'table tbody tr:nth-child(2) td:nth-child(2)', text: 'my new sample 1'
      assert_selector 'table tbody tr:nth-child(2) td:nth-child(8)', text: 'a'
    end

    test 'group without projects should not render sample actions dropdown' do
      group = groups(:group_seven)
      ### SETUP START ###
      visit group_samples_url(group)

      assert_no_selector 'table'
      assert_selector 'div.empty_state_message'
      assert_text I18n.t('groups.samples.table.no_associated_samples')
      assert_text I18n.t('groups.samples.table.no_samples')

      assert_no_selector 'button', text: I18n.t(:'shared.samples.actions_dropdown.label')
    end

    test 'transfer dialog sample listing' do
      ### SETUP START ###
      samples = pluck_sample_names_and_puids(@group.project_namespaces)

      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')

      assert_selector 'tbody input[name="sample_ids[]"]:checked', count: 20

      assert_selector 'tfoot', text: 'Samples: 26'
      assert_selector 'tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      samples.each do |sample|
        assert_selector '#list_selections', text: sample[0]
        assert_selector '#list_selections', text: sample[1]
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
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20

      assert_selector 'tfoot', text: 'Samples: 26'
      assert_selector 'tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('samples.transfers.dialog.description.plural').gsub!('COUNT_PLACEHOLDER',
                                                                              '26')
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
      check "checkbox_sample_#{@sample1.id}"
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('samples.transfers.dialog.description.singular')
      ### VERIFY END ###
    end

    test 'transfer samples' do
      ### SETUP START ###
      project4 = projects(:project4)
      samples = pluck_sample_names_and_puids(@group.project_namespaces)

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      # target project has 2 samples prior to transfer
      visit namespace_project_samples_url(project4.namespace.parent, project4)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select first sample
      check "checkbox_sample_#{@sample1.id}"
      assert_selector 'table tfoot', text: 'Samples: 26 Selected: 1'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '1'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      # select destination project
      find('input.select2-input').click
      find("li[data-value='#{project4.id}']").click

      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1

      # flash msg
      assert_text I18n.t('samples.transfers.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 25,
                                                                                      locale: @user.locale))

      # destination project received transferred samples
      visit namespace_project_samples_url(project4.namespace.parent, project4)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                      locale: @user.locale))
      assert_selector '#samples-table table tbody tr:first-child th:first-child', text: samples[1]
      assert_selector '#samples-table table tbody tr:first-child td:nth-child(2)', text: samples[0]
      ### VERIFY END ###
    end

    test 'dialog close button hidden during transfer samples' do
      ### SETUP START ###
      project4 = projects(:project4)

      # originating project has 3 samples prior to transfer
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select all 3 samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      # close button available before confirming
      assert_selector 'button.dialog--close'
      # select destination project
      find('input.select2-input').click
      find("li[data-value='#{project4.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      # close button hidden during transfer
      assert_no_selector 'button.dialog--close'
      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1
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
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      # launch transfer dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('samples.transfers.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{project4.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1

      # samples listing should no longer appear in dialog
      assert_no_selector '#list_selections'
      # error msg displayed in dialog
      assert_text I18n.t('samples.transfers.create.no_samples_transferred_error')
      ### VERIFY END ###
    end

    test 'transfer samples with and without same name in destination project' do
      # only samples without a matching name to samples in destination project will transfer

      ### SETUP START ###
      project4 = projects(:project4)
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)
      sample28 = samples(:sample28)
      sample29 = samples(:sample29)

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      # target project has 2 samples prior to transfer
      visit namespace_project_samples_url(project4.namespace.parent, project4)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))

      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{project4.id}']").click
      click_on I18n.t('samples.transfers.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::TransferJob]
      assert_performed_jobs 1

      # error messages in dialog
      assert_text I18n.t('samples.transfers.create.error')

      assert_text I18n.t('services.samples.transfer.unauthorized', sample_ids: sample28.id.to_s).gsub(':', '')

      # colon is removed from translation in UI
      assert_text I18n.t('services.samples.transfer.sample_exists', sample_puid: sample29.puid,
                                                                    sample_name: sample29.name).gsub(':', '')

      click_button I18n.t('shared.samples.errors.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # verify sample1 and 2 transferred, sample 28, sample 29 did not
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 2, count: 2,
                                                                                      locale: @user.locale))
      assert_no_selector "tr[id='#{dom_id(sample1)}']"
      assert_no_selector "tr[id='#{dom_id(sample2)}']"
      assert_selector "tr[id='#{dom_id(sample28)}']"
      assert_selector "tr[id='#{dom_id(sample29)}']"

      # destination project
      visit namespace_project_samples_url(project4.namespace.parent, project4)
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))

      click_on I18n.t(:'samples.table_component.puid')

      assert_selector "tr[id='#{dom_id(sample1)}']"
      assert_selector "tr[id='#{dom_id(sample2)}']"
      assert_no_selector "tr[id='#{dom_id(sample28)}']"
      assert_no_selector "tr[id='#{dom_id(sample29)}']"
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
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 4
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 4"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '4'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      # Only projects within group are visible for maintainer to transfer to
      find('input.select2-input').click
      group_three_projects.each do |proj|
        total_projects_transfer_to_count += 1 if find("li[data-value='#{proj.id}']")
      end

      assert_equal total_projects_transfer_to_count, group_three_projects.count
      ### VERIFY END ###
    end

    test 'empty state of transfer sample project selection' do
      ### SETUP START ###
      group_three = groups(:group_three)
      visit group_samples_url(group_three)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 4, count: 4,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      # select samples
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 4
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 4"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '4'

      # launch dialog
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.transfer')
      assert_selector 'h1.dialog--title', text: I18n.t('samples.transfers.dialog.title')
      # fill destination input
      find('input.select2-input').fill_in with: 'invalid project name or puid'
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.transfers.dialog.empty_state')
      ### VERIFY END ###
    end

    test 'singular clone dialog description' do
      ### SETUP START ###
      visit group_samples_url(@group)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      check "checkbox_sample_#{@sample1.id}"
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('samples.clones.dialog.description.singular')
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
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t(
        'samples.clones.dialog.description.plural'
      ).gsub! 'COUNT_PLACEHOLDER', '26'
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
      check "checkbox_sample_#{@sample1.id}"
      check "checkbox_sample_#{@sample2.id}"
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 2
      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '2'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_selector '#list_selections', text: @sample1.name
      assert_selector '#list_selections', text: @sample1.puid
      assert_selector '#list_selections', text: @sample2.name
      assert_selector '#list_selections', text: @sample2.puid
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
      check "checkbox_sample_#{@sample1.id}"
      check "checkbox_sample_#{@sample2.id}"
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1

      # flash msg
      assert_text I18n.t('samples.clones.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # samples table now contains both original and cloned samples
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 28,
                                                                                      locale: @user.locale))
      # duplicated sample names
      assert_selector '#samples-table table tbody td', text: @sample1.name, count: 2
      assert_selector '#samples-table table tbody td', text: @sample2.name, count: 2

      # samples now exist in project2 samples table
      visit namespace_project_samples_url(@group, @project2)
      # verify samples table has loaded to prevent flakes
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 22,
                                                                                      locale: @user.locale))
      assert_selector '#samples-table table tbody td', text: @sample1.name, count: 1
      assert_selector '#samples-table table tbody td', text: @sample2.name, count: 1
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
      check "checkbox_sample_#{@sample1.id}"
      check "checkbox_sample_#{@sample2.id}"

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      # close button available before confirming cloning
      assert_selector 'button.dialog--close'
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')
      # close button hidden during cloning
      assert_no_selector 'button.dialog--close'
      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1
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
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: 'Samples: 26'
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      # clear localstorage
      Capybara.execute_script 'sessionStorage.clear()'
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1

      # error msg
      assert_text I18n.t('samples.clones.create.no_samples_cloned_error')
      assert_text I18n.t('services.samples.clone.empty_sample_ids')
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
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{@project1.id}']").click
      click_on I18n.t('samples.clones.dialog.submit_button')

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1

      # errors that a sample with the same name as sample30 already exists in project25
      assert_text I18n.t('samples.clones.create.error')
      assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample1.puid,
                                                                 sample_name: @sample1.name).gsub(':', '')
      assert_text I18n.t('services.samples.clone.sample_exists', sample_puid: @sample2.puid,
                                                                 sample_name: @sample2.name).gsub(':', '')
      click_on I18n.t('shared.samples.errors.ok_button')

      # verify dialog is closed
      assert_no_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')

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
      click_button I18n.t('common.controls.select_all')
      assert_selector 'table tbody input[name="sample_ids[]"]:checked', count: 20
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '26'

      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').fill_in with: 'invalid project name or puid'
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.clones.dialog.empty_state')
      ### VERIFY END ###
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
      check "checkbox_sample_#{@sample1.id}"

      # verify 1 sample selected in originating project
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 26"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '1'

      # clone sample
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.clone')

      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      find('input.select2-input').click
      find("li[data-value='#{@project2.id}']").click
      click_on I18n.t('samples.clones.dialog.submit_button')
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')
      assert_text I18n.t('shared.progress_bar.in_progress')

      perform_enqueued_jobs only: [::Samples::CloneJob]
      assert_performed_jobs 1

      # flash msg
      assert_text I18n.t('samples.clones.create.success')
      click_button I18n.t('shared.samples.success.ok_button')

      assert_no_selector 'h1.dialog--title', text: I18n.t('samples.clones.dialog.title')

      # verify page has finished loading
      assert_no_selector 'html[aria-busy="true"]'

      # verify no samples selected anymore
      assert_selector 'table tfoot', text: "#{I18n.t('samples.table_component.counts.samples')}: 27"
      assert_selector 'table tfoot strong[data-selection-target="selected"]', text: '0'
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
      check "checkbox_sample_#{@sample1.id}"
      check "checkbox_sample_#{@sample2.id}"
      # click delete samples button
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      # verify dialog contents
      assert_selector 'h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      assert_selector '#list_selections', text: @sample1.name
      assert_selector '#list_selections', text: @sample1.puid
      assert_selector '#list_selections', text: @sample2.name
      assert_selector '#list_selections', text: @sample2.name
      # submit
      click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
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
      check "checkbox_sample_#{sample25.id}"
      check "checkbox_sample_#{sample28.id}"
      # click delete samples button
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      # verify dialog contents
      assert_selector 'h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      # submit
      click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')
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
      check "checkbox_sample_#{sample28.id}"
      # click delete samples button
      click_button I18n.t('shared.samples.actions_dropdown.label')
      click_button I18n.t('shared.samples.actions_dropdown.delete_samples')

      # verify dialog contents
      assert_selector 'h1', text: I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.title')
      # submit
      click_button I18n.t('samples.deletions.destroy_multiple_confirmation_dialog.submit_button')

      ### ACTIONS END ###

      ### VERIFY START ###
      assert_text I18n.t('samples.deletions.destroy.no_deleted_samples')
      assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                                      locale: @user.locale))
      ### VERIFY END ###
    end
  end
end
