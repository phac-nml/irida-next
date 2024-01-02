# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @group = groups(:group_one)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample9 = samples(:sample9)
    end

    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.pagination.next')
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_selector 'tbody > tr', count: 6
      click_on I18n.t(:'components.pagination.previous')
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
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample1).name
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.pagination.next')
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_selector 'tbody > tr', count: 6
      assert_text samples(:sample28).name
      click_on I18n.t(:'components.pagination.previous')
      assert_selector 'tbody > tr', count: 20

      click_link samples(:sample1).name
      assert_selector 'h1', text: samples(:sample1).name

      visit group_samples_url(group)

      click_link samples(:sample1).name
      assert_selector 'h1', text: samples(:sample1).name

      visit group_samples_url(group)

      assert_selector 'a', text: I18n.t(:'components.pagination.next')
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')

      click_link samples(:sample28).name
      assert_selector 'h1', text: samples(:sample28).name
    end

    test 'cannot access group samples' do
      login_as users(:user_no_access)

      visit group_samples_url(@group)

      assert_text I18n.t(:'action_policy.policy.group.sample_listing?', name: @group.name)
    end

    test 'can search the list of samples by name' do
      visit group_samples_url(@group)

      assert_selector 'table tbody#group-samples-table-body tr', count: 20
      assert_text @sample1.name
      assert_text @sample2.name

      fill_in I18n.t(:'groups.samples.index.search.placeholder'), with: 'Sample 1'

      assert_selector 'table tbody#group-samples-table-body tr', count: 13
      assert_text @sample1.name
      assert_no_text @sample2.name
    end

    test 'can sort the list of samples' do
      visit group_samples_url(@group)

      assert_selector 'table tbody#group-samples-table-body tr', count: 20
      within first('table tbody#group-samples-table-body tr td') do
        assert_text @sample1.name
      end

      click_on I18n.t(:'groups.samples.index.sorting.updated_at_desc')
      click_on I18n.t(:'groups.samples.index.sorting.name_desc')

      assert_text I18n.t(:'groups.samples.index.sorting.name_desc')
      assert_selector 'table tbody#group-samples-table-body tr', count: 20
      within first('table tbody#group-samples-table-body tr:nth-child(3) td') do
        assert_text @sample9.name
      end
    end

    test 'can filter and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_selector 'table tbody#group-samples-table-body tr', count: 20
      within first('table tbody#group-samples-table-body tr td') do
        assert_text @sample1.name
      end

      fill_in I18n.t(:'groups.samples.index.search.placeholder'), with: 'Sample 1'

      assert_selector 'table tbody#group-samples-table-body tr', count: 13
      assert_text @sample1.name
      assert_no_text @sample2.name

      click_on I18n.t(:'groups.samples.index.sorting.updated_at_desc')
      click_on I18n.t(:'groups.samples.index.sorting.name_desc')

      assert_text I18n.t(:'groups.samples.index.sorting.name_desc')
      assert_selector 'table tbody#group-samples-table-body tr', count: 13
      within first('table tbody#group-samples-table-body tr:nth-child(13) td') do
        assert_text @sample1.name
      end
    end

    test 'can sort and then filter the list of samples' do
      visit group_samples_url(@group)

      assert_selector 'table tbody#group-samples-table-body tr', count: 20
      within first('table tbody#group-samples-table-body tr td') do
        assert_text @sample1.name
      end

      click_on I18n.t(:'groups.samples.index.sorting.updated_at_desc')
      click_on I18n.t(:'groups.samples.index.sorting.name_desc')

      assert_text I18n.t(:'groups.samples.index.sorting.name_desc')
      assert_selector 'table tbody#group-samples-table-body tr', count: 20
      within first('table tbody#group-samples-table-body tr:nth-child(3) td') do
        assert_text @sample9.name
      end

      fill_in I18n.t(:'groups.samples.index.search.placeholder'), with: 'Sample 1'

      assert_selector 'table tbody#group-samples-table-body tr', count: 13
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample9.name
    end
  end
end
