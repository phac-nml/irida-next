# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    def setup
      Flipper.enable(:metadata_import_field_selection)

      @user = users(:john_doe)
      login_as @user
      @group = groups(:group_one)
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'button[disabled="disabled"]',
                      text: I18n.t(:'viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                           locale: @user.locale))
      assert_selector 'tbody > tr', count: 6
      click_on I18n.t(:'viral.pagy.pagination_component.previous', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample1).name
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'button[disabled="disabled"]',
                      text: I18n.t(:'viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                           locale: @user.locale))
      assert_selector 'tbody > tr', count: 6
      assert_text samples(:sample28).name
      click_on I18n.t(:'viral.pagy.pagination_component.previous', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      assert_selector 'tbody > tr', count: 20

      click_link samples(:sample1).name
      assert_selector 'h1', text: samples(:sample1).name

      visit group_samples_url(group)

      click_link samples(:sample1).name
      assert_selector 'h1', text: samples(:sample1).name

      visit group_samples_url(group)

      assert_selector 'a', text: I18n.t(:'viral.pagy.pagination_component.next', locale: @user.locale)
      assert_selector 'button[disabled="disabled"]',
                      text: I18n.t(:'viral.pagy.pagination_component.previous', locale: @user.locale)

      click_on I18n.t(:'viral.pagy.pagination_component.next', locale: @user.locale)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 21, to: 26, count: 26,
                                                                           locale: @user.locale))

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

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
        assert_text @sample1.name
        assert_text @sample2.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text 'Samples: 13'
      within('table tbody') do
        assert_selector 'tr', count: 13

        assert_text @sample1.name
        assert_no_text @sample2.name
      end
    end

    test 'can sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      # Because PUIDs are not always generated the same, issues regarding order have occurred when hard testing
      # the expected ordering of samples based on PUID. To resolve this, we will gather the first 4 PUIDs and ensure
      # they are ordered as expected against one another.
      within('table tbody') do
        assert_selector 'tr', count: 20
      end

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
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_down'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end
    end

    test 'can filter by name and then sort the list of samples' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text 'Samples: 13'
      within('table tbody') do
        assert_selector 'tr', count: 13

        assert_text @sample1.name
        assert_no_text @sample2.name
      end

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

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      assert_selector 'table tbody tr', count: 20
      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 1
        assert_text @sample1.name
        assert_no_text @sample2.name
      end
      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'

      within('table tbody') do
        assert_selector 'tr', count: 1
      end
      assert_selector 'table tbody tr:first-child th', text: @sample1.puid
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: @sample1.name
    end

    test 'can change pagination and then filter by puid' do
      visit group_samples_url(@group)

      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      assert_selector 'div#limit-component button div span', text: '10'
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 10
        assert_text @sample1.puid
        assert_text @sample2.puid
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 1
        assert_text @sample1.name
        assert_no_text @sample2.name
      end
      assert_selector 'div#limit-component button div span', text: '10'
    end

    test 'can change pagination and then toggle metadata' do
      visit group_samples_url(@group)

      within('div#limit-component') do
        find('button').click
        click_link '10'
      end

      assert_selector 'div#limit-component button div span', text: '10'
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 10
      end

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'all'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 10, count: 26,
                                                                           locale: @user.locale))

      within('table tbody') do
        assert_selector 'tr', count: 10
      end

      within('table thead tr') do
        assert_selector 'th', count: 9
      end
      assert_selector 'div#limit-component button div span', text: '10'
    end

    test 'can sort and then filter the list of samples by name' do
      visit group_samples_url(@group)

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end
      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: 'Sample 1'
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

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

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      within('table tbody tr:first-child th') do
        assert_text @sample1.puid
      end

      click_on 'Sample Name'
      assert_selector 'table thead th:nth-child(2) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end

      click_on 'Created'
      assert_selector 'table thead th:nth-child(4) svg.icon-arrow_up'
      within('table tbody') do
        assert_selector 'tr:nth-child(3) th', text: @sample28.puid
        assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @sample28.name
        assert_selector 'tr:nth-child(4) th', text: @sample25.puid
        assert_selector 'tr:nth-child(4) td:nth-child(2)', text: @sample25.name
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.puid
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 1, count: 1,
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

      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_on 'Last Updated'
      assert_selector 'table thead th:nth-child(5) svg.icon-arrow_up'

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'all'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      within('table thead tr') do
        assert_selector 'th', count: 9
      end

      within('table tbody tr:first-child') do
        assert_text @sample30.name
        assert_selector 'td:nth-child(7) button', text: 'value1'
        assert_selector 'td:nth-child(8) button', text: 'value2'
        assert_selector 'td:nth-child(9) button', text: ''
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'none'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_selector 'table thead tr th', count: 6
    end

    test 'can sort samples by metadata column' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))
      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'all'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      within('table thead tr') do
        assert_selector 'th', count: 9
      end

      click_on 'metadatafield1'
      assert_selector 'table thead th:nth-child(7) svg.icon-arrow_up'

      assert_selector 'tbody tr:first-child th', text: @sample30.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample30.name

      click_on 'metadatafield2'
      assert_selector 'table thead th:nth-child(8) svg.icon-arrow_up'

      assert_selector 'tbody tr:first-child th', text: @sample30.puid
      assert_selector 'tbody tr:first-child td:nth-child(2)', text: @sample30.name

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'none'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      assert_selector 'table thead th:nth-child(5) svg.icon-arrow_down'
      within('tbody') do
        assert_selector 'tr:first-child th', text: @sample1.puid
        assert_selector 'tr:first-child td:nth-child(2)', text: @sample1.name
        assert_selector 'tr:nth-child(2) th', text: @sample2.puid
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @sample2.name
      end
    end

    test 'filter samples with advanced search' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample9.id}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          within all("div[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='puid']").select_option
            find("select[name$='[operator]']").find("option[value='in']").select_option
            find("input[name$='[value][]']").fill_in with: "#{@sample1.puid}, #{@sample2.puid}"
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 2
        # sample1 & sample2 found
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample9.id}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample9.id}']"
      end
    end

    test 'filter samples with advanced search using metadata fields names with extra periods' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample3.id}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          within all("div[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.unique.metadata.field']").select_option
            find("select[name$='[operator]']").find("option[value='=']").select_option
            find("input[name$='[value]']").fill_in with: @sample28.metadata['unique.metadata.field']
          end
        end

        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        # sample28 found
        assert_no_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample3.id}']"
        assert_selector "tr[id='#{@sample28.id}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample3.id}']"
      end
    end

    test 'filter samples with advanced search using exists operator' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
                                                                           locale: @user.locale))

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample3.id}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        within all("div[data-advanced-search-target='groupsContainer']")[0] do
          within all("div[data-advanced-search-target='conditionsContainer']")[0] do
            find("select[name$='[field]']").find("option[value='metadata.unique.metadata.field']").select_option
            find("select[name$='[operator]']").find("option[value='exists']").select_option
          end
        end
        click_button I18n.t(:'advanced_search_component.apply_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector 'tr', count: 1
        # sample28 found
        assert_no_selector "tr[id='#{@sample1.id}']"
        assert_no_selector "tr[id='#{@sample2.id}']"
        assert_no_selector "tr[id='#{@sample3.id}']"
        assert_selector "tr[id='#{@sample28.id}']"
      end

      click_button I18n.t(:'advanced_search_component.title')
      within '#advanced-search-dialog' do
        assert_selector 'h1', text: I18n.t(:'advanced_search_component.title')
        click_button I18n.t(:'advanced_search_component.clear_filter_button')
      end

      within '#samples-table table tbody' do
        assert_selector "tr[id='#{@sample1.id}']"
        assert_selector "tr[id='#{@sample2.id}']"
        assert_selector "tr[id='#{@sample3.id}']"
      end
    end

    test 'selecting / deselecting all samples' do
      visit group_samples_url(@group)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
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
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 26,
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
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

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
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_text 'Samples: 26'
      assert_selector 'tfoot strong[data-selection-target="selected"]', text: '0'
      assert_selector 'table tbody tr', count: 20
    end

    test 'should import metadata via csv' do
      visit group_samples_url(@group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv')
        find('#file_import_sample_id_column', wait: 1).find("option[value='sample_puid']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield1']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield2']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield3']").select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
    end

    test 'should not import metadata via invalid file type' do
      visit group_samples_url(@group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/invalid.txt')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='header']").select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')

        perform_enqueued_jobs only: [::Samples::MetadataImportJob]
      end
      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('services.spreadsheet_import.invalid_file_extension')
      end
    end

    test 'should import metadata with ignore empty values' do
      group = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit group_samples_url(group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/contains_empty_values_with_puid.csv')
        find('#file_import_sample_id_column', wait: 1).find("option[value='sample_puid']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield1']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield2']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield3']").select_option
        check 'Ignore empty values'
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      visit namespace_project_sample_url(group, project, sample)
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
      group = groups(:subgroup_twelve_a)
      project = projects(:project29)
      sample = samples(:sample32)
      visit group_samples_url(group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/contains_empty_values_with_puid.csv')
        find('#file_import_sample_id_column', wait: 1).find("option[value='sample_puid']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield1']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield2']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield3']").select_option
        assert_not find_field('Ignore empty values').checked?
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.success.description')
        click_on I18n.t('shared.samples.metadata.file_imports.success.ok_button')
      end
      visit namespace_project_sample_url(group, project, sample)
      assert_text I18n.t('projects.samples.show.tabs.metadata')
      click_on I18n.t('projects.samples.show.tabs.metadata')
      within %(turbo-frame[id="table-listing"]) do
        assert_text I18n.t('projects.samples.show.table_header.key').upcase
        assert_selector 'table#metadata-table tbody tr', count: 2
        assert_no_text 'metadatafield1'
      end
    end

    test 'should not import metadata with duplicate header errors' do
      visit group_samples_url(@group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/duplicate_headers.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        find('#file_import_metadata_columns', wait: 1).find(:xpath, 'option[1]').select_option
        find('#file_import_metadata_columns', wait: 1).find(:xpath, 'option[2]').select_option
        find('#file_import_metadata_columns', wait: 1).find(:xpath, 'option[3]').select_option
        find('#file_import_metadata_columns', wait: 1).find(:xpath, 'option[4]').select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('services.spreadsheet_import.duplicate_column_names')
      end
    end

    test 'should not import metadata with missing metadata row errors' do
      visit group_samples_url(@group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_rows.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield1']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield2']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield3']").select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('services.spreadsheet_import.missing_data_row')
      end
    end

    test 'should not import metadata with missing metadata column errors' do
      visit group_samples_url(@group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]', Rails.root.join('test/fixtures/files/metadata/missing_metadata_columns.csv')
        find('#file_import_sample_id_column', wait: 1).find(:xpath, 'option[2]').select_option
        assert find("input[value='#{I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')}'").disabled?
      end
    end

    test 'should partially import metadata with missing sample errors' do
      visit group_samples_url(@group)

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'all'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      assert_selector '#samples-table table thead tr th', count: 9
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/mixed_project_samples_with_puid.csv')
        find('#file_import_sample_id_column', wait: 1).find("option[value='sample_puid']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield1']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield2']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield3']").select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end
      assert_selector '#samples-table table thead tr th', count: 10
    end

    test 'should not import metadata with analysis values' do
      group = groups(:group_twelve)
      visit group_samples_url(group)
      click_link I18n.t('groups.samples.index.import_metadata_button'), match: :first
      within('div[data-metadata--file-import-loaded-value="true"]') do
        attach_file 'file_import[file]',
                    Rails.root.join('test/fixtures/files/metadata/contains_analysis_values_with_puid.csv')
        find('#file_import_sample_id_column', wait: 1).find("option[value='sample_puid']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield1']").select_option
        find('#file_import_metadata_columns', wait: 1).find("option[value='metadatafield3']").select_option
        click_on I18n.t('shared.samples.metadata.file_imports.dialog.submit_button')
      end
      assert_text I18n.t('shared.samples.metadata.file_imports.dialog.spinner_message')

      perform_enqueued_jobs only: [::Samples::MetadataImportJob]

      within %(turbo-frame[id="samples_dialog"]) do
        assert_text I18n.t('shared.samples.metadata.file_imports.errors.description')
        click_on I18n.t('shared.samples.metadata.file_imports.errors.ok_button')
      end
    end

    test 'can update metadata value that is not from an analysis' do
      ### SETUP START ###
      visit group_samples_url(@group)

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      fill_in placeholder: I18n.t(:'groups.samples.table_filter.search.placeholder'), with: @sample1.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'all'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      within('table thead tr') do
        assert_selector 'th', count: 9
      end

      within 'div.overflow-auto.scrollbar' do |div|
        div.scroll_to div.find('table thead th:nth-child(7)')
      end
      ### SETUP END ###

      ### ACTIONS START ###
      within('table tbody tr:first-child td:nth-child(7)') do
        within('form[method="get"]') do
          find('button').click
        end
        assert_selector "form[data-controller='inline-edit']"

        within('form[data-controller="inline-edit"]') do
          find('input[name="value"]').send_keys 'value2'
          find('input[name="value"]').send_keys :return
        end
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_no_selector "form[data-controller='inline-edit']"
        assert_selector 'form[method="get"]'
        assert_selector 'button', text: 'value2'
        ### VERIFY END ###
      end
    end

    test 'project analysts should not be able to edit samples' do
      ### SETUP START ###
      login_as users(:ryan_doe)
      visit group_samples_url(@group)

      # toggle metadata on for samples table
      click_button I18n.t('shared.samples.metadata_templates.label')
      choose 'q[metadata_template]', option: 'all'

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      within('table thead tr') do
        assert_selector 'th', count: 9
      end

      fill_in placeholder: I18n.t(:'projects.samples.table_filter.search.placeholder'), with: @sample28.name
      find('input.t-search-component').native.send_keys(:return)

      assert_selector 'div#spinner'
      assert_no_selector 'div#spinner'

      ### SETUP END ###

      ### VERIFY START ###
      within('table tbody tr:first-child td:nth-child(7)') do
        assert_no_selector "form[method='get']"
      end
      ### VERIFY END ###
    end
  end
end
