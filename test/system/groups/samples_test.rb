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
      @sample25 = samples(:sample25)
      @sample28 = samples(:sample28)
      @sample30 = samples(:sample30)
      @sample31 = samples(:sample31)
    end

    def retrieve_puids
      puids = []
      within first('table tbody') do
        (1..4).each do |n|
          puids << first("tr:nth-child(#{n}) th").text
        end
      end
      puids
    end
    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.pagination.next')
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_text 'Displaying items 21-26 of 26 in total'
      assert_selector 'tbody > tr', count: 6
      click_on I18n.t(:'components.pagination.previous')
      assert_text 'Displaying items 1-20 of 26 in total'
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
      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample1).name
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.pagination.next')
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_text 'Displaying items 21-26 of 26 in total'
      assert_selector 'tbody > tr', count: 6
      assert_text samples(:sample28).name
      click_on I18n.t(:'components.pagination.previous')
      assert_text 'Displaying items 1-20 of 26 in total'
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
      assert_text 'Displaying items 21-26 of 26 in total'

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

      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'table tbody tr', count: 20
      assert_text @sample1.name
      assert_text @sample2.name

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: 'Sample 1'

      assert_text 'Samples: 13'
      assert_selector 'table tbody tr', count: 13

      assert_text @sample1.name
      assert_no_text @sample2.name
    end

    test 'can sort the list of samples' do
      visit group_samples_url(@group)

      assert_text 'Displaying items 1-20 of 26 in total'
      # Because PUIDs are not always generated the same, issues regarding order have occurred when hard testing
      # the expected ordering of samples based on PUID. To resolve this, we will gather the first 4 PUIDs and ensure
      # they are ordered as expected against one another.
      assert_selector 'table tbody tr', count: 20

      click_on 'Sample ID'
      assert_selector 'table thead th:first-child svg.icon-arrow_up'
      puids = retrieve_puids
      (puids.length - 1).times do |n|
        assert puids[n] < puids[n + 1]
      end

      click_on 'Sample ID'
      assert_selector 'table thead th:first-child svg.icon-arrow_down'
      puids = retrieve_puids
      (puids.length - 1).times do |n|
        assert puids[n] > puids[n + 1]
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within first('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within first('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_down'
      within first('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end
    end

    test 'can filter by name and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'table tbody tr', count: 20
      within first('table tbody tr th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: 'Sample 1'

      assert_text 'Samples: 13'
      assert_selector 'table tbody tr', count: 13

      assert_text @sample1.name
      assert_no_text @sample2.name

      assert_no_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      assert_selector 'tbody tr:first-child th', text: @sample1.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample1.name

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_down'

      assert_selector 'tbody tr:last-child th', text: @sample1.puid
      assert_selector 'tbody tr:last-child td:nth-child(2)', text: @sample1.name
    end

    test 'can filter by puid and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'table tbody tr', count: 20
      within first('table tbody tr th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: @sample1.puid

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1
      assert_text @sample1.name
      assert_no_text @sample2.name

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      assert_selector 'table tbody tr', count: 1
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
    end

    test 'can sort and then filter the list of samples by name' do
      visit group_samples_url(@group)

      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'table tbody tr', count: 20
      within first('table tbody tr th') do
        assert_text @sample1.puid
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within first('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within first('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: 'Sample 1'

      assert_text 'Displaying 13 items'
      assert_selector 'table tbody tr', count: 13
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample9.name
    end

    test 'can sort and then filter the list of samples by puid' do
      visit group_samples_url(@group)

      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'table tbody tr', count: 20
      within first('table tbody tr th') do
        assert_text @sample1.puid
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within first('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within first('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: @sample1.puid

      assert_text 'Displaying 1 item'
      assert_selector 'table tbody tr', count: 1
      assert_text @sample1.name
      assert_no_text @sample2.name
      assert_no_text @sample9.name
    end

    test 'should be able to toggle metadata' do
      visit group_samples_url(@group)
      assert_text 'Displaying items 1-20 of 26 in total'
      click_on 'Last Updated'
      assert_selector 'label', text: I18n.t('groups.samples.index.search.metadata'), count: 1
      assert_selector 'table thead tr th', count: 6
      find('label', text: I18n.t('groups.samples.index.search.metadata')).click
      assert_selector 'table thead tr th', count: 8
      within first('table tbody tr:first-child') do
        assert_text @sample30.name
        assert_selector 'td:nth-child(7)', text: 'value1'
        assert_selector 'td:nth-child(8)', text: 'value2'
      end
      find('label', text: I18n.t('groups.samples.index.search.metadata')).click
      assert_selector 'table thead tr th', count: 6
    end

    test 'can sort samples by metadata column' do
      visit group_samples_url(@group)
      assert_text 'Displaying items 1-20 of 26 in total'
      assert_selector 'label', text: I18n.t('groups.samples.index.search.metadata'), count: 1
      assert_selector 'table thead tr th', count: 6
      find('label', text: I18n.t('groups.samples.index.search.metadata')).click
      assert_selector 'table thead tr th', count: 8

      click_on 'metadatafield1'
      assert_selector 'table thead th:nth-child(7) svg.icon-arrow_up'

      assert_selector 'tbody tr:first-child th', text: @sample30.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample30.name
      assert_selector 'tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name

      click_on 'metadatafield2'
      assert_selector 'table thead th:nth-child(8) svg.icon-arrow_up'

      assert_selector 'tbody tr:first-child th', text: @sample30.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample30.name
      assert_selector 'tbody tr:nth-child(2) th', text: @sample2.puid
      assert_selector 'tbody tr:nth-child(2) td:nth-child(2)', text: @sample2.name

      # toggling metadata again causes sort to be reset
      find('label', text: I18n.t(:'projects.samples.shared.metadata_toggle.label')).click
      assert_selector 'table thead tr th', count: 6

      assert_selector 'table thead th:nth-child(5) svg.icon-arrow_down'
      within first('tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end
    end

    test 'filtering samples by list of  sample puids' do
      visit group_samples_url(@group)
      assert_text 'Displaying items 1-20 of 26 in total'
      within 'tbody' do
        assert_selector 'tr', count: 20
        assert_selector 'tr th', text: @sample1.puid
        assert_selector 'tr th', text: @sample2.puid
        assert_selector 'tr th', text: @sample9.puid
      end

      find("button[aria-label='#{I18n.t(:'components.list_filter.title')}").click
      within 'dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        find("input[name='q[name_or_puid_in][]']").send_keys "#{@sample1.puid}, #{@sample2.puid}"
        assert_selector 'span.label', count: 1
        assert_selector 'span.label', text: @sample1.puid
        find("input[name='q[name_or_puid_in][]']").text @sample2.puid
        click_button I18n.t(:'components.list_filter.apply')
      end

      within 'tbody' do
        assert_selector 'tr', count: 2
        assert_selector 'tr th', text: @sample1.puid
        assert_selector 'tr th', text: @sample2.puid
        assert_no_selector 'tr th', text: @sample9.puid
      end

      find("button[aria-label='#{I18n.t(:'components.list_filter.title')}").click
      within 'dialog' do
        assert_selector 'h1', text: I18n.t(:'components.list_filter.title')
        click_button I18n.t(:'components.list_filter.clear')
        click_button I18n.t(:'components.list_filter.apply')
      end
      within 'tbody' do
        assert_selector 'tr', count: 20
      end
    end

    test 'selecting / deselecting all samples' do
      visit group_samples_url(@group)
      assert_text 'Displaying items 1-20 of 26 in total'
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end
      find('input[name="select"]').click
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

      find('input[name="select"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 20
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '26'
      end
      find('input[name="select"]').click
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
    end

    test 'selecting samples while filtering' do
      visit group_samples_url(@group)
      assert_text 'Displaying items 1-20 of 26 in total'
      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 20
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end
      within 'tfoot' do
        assert_text 'Samples: 26'
        assert_selector 'strong[data-selection-target="selected"]', text: '0'
      end

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: @sample1.name

      assert_text 'Samples: 1'
      assert_selector 'table tbody tr', count: 1

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]', count: 1
        assert_selector 'input[name="sample_ids[]"]:checked', count: 0
      end

      find('input[name="select"]').click

      within 'tbody' do
        assert_selector 'input[name="sample_ids[]"]:checked', count: 1
      end
      within 'tfoot' do
        assert_text 'Samples: 1'
        assert_selector 'strong[data-selection-target="selected"]', text: '1'
      end

      fill_in placeholder: I18n.t(:'groups.samples.index.search.placeholder'), with: ' '

      assert_text 'Samples: 26'
      assert_selector 'tfoot strong[data-selection-target="selected"]', text: '0'
      assert_selector 'table tbody tr', count: 20
    end
  end
end
