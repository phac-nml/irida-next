# frozen_string_literal: true

require 'application_system_test_case'

module Dashboard
  class GroupsTest < ApplicationSystemTestCase
    def setup
      login_as users(:alph_abet)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @subgroup12b = groups(:subgroup_twelve_b)
    end

    test 'can see the list of groups' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'components.pagination.next')
      assert_text I18n.t(:'components.pagination.previous')
      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 6
        [*('f'..'a')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'components.pagination.previous')
      assert_text I18n.t(:'components.pagination.next')
      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end
    end

    test 'can sort the list of groups by name descending' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.name_desc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.name_desc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_z).name
      end
    end

    test 'can sort the list of groups by name ascending' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.name_asc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.name_asc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_a).name
      end
    end

    test 'can sort the list of groups by updated at desc' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.updated_at_desc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.updated_at_desc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_a).name
      end
    end

    test 'can sort the list of groups by updated at asc' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.updated_at_asc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.updated_at_asc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_z).name
      end
    end

    test 'can sort the list of groups by created_at asc' do
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      within 'ul.groups-list.namespace-list-tree' do
        assert_selector 'li', count: 20
        [*('z'..'g')].each do |letter|
          assert_text groups(:"group_#{letter}").name
        end
      end

      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      click_on I18n.t(:'dashboard.groups.index.sorting.created_at_asc')
      assert_no_text I18n.t(:'dashboard.groups.index.sorting.created_at_desc')
      assert_text I18n.t(:'dashboard.groups.index.sorting.created_at_asc')

      within 'ul.groups-list.namespace-list-tree li:first-child' do
        assert_text groups(:group_z).name
      end
    end

    test 'can expand parent groups to see their children' do
      login_as users(:john_doe)
      group1 = groups(:group_one)
      subgroup1 = groups(:subgroup1)
      visit dashboard_groups_url

      within("li#group_#{group1.id}") do
        assert_text group1.name
        assert_no_selector 'ul.groups-list.namespace-list-tree'
        assert_no_text subgroup1.name
        find('a.folder-toggle-wrap').click
      end

      within("li#group_#{group1.id}") do
        assert_text group1.name
        assert_text subgroup1.name
      end
    end

    test 'can create a group from listing page' do
      visit dashboard_groups_url

      click_link I18n.t(:'dashboard.groups.index.create_group_button')

      within %(div[data-controller="slugify"][data-controller-connected="true"]) do
        fill_in I18n.t(:'activerecord.attributes.group.name'), with: 'New group'

        assert_selector %(input[data-slugify-target="path"]) do |input|
          assert_equal 'new-group', input['value']
        end

        fill_in 'Description', with: 'New group description'
        click_on I18n.t(:'groups.create.submit')
      end

      assert_text I18n.t(:'groups.create.success')
      assert_selector 'h1', text: 'New group'
    end

    test 'can search for a group by name or puid' do
      visit dashboard_groups_url

      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: 'group a'
      find('input.t-search-component').native.send_keys(:return)

      assert_text groups(:group_a).name
      assert_no_text groups(:group_b).name

      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: groups(:group_b).puid
      find('input.t-search-component').native.send_keys(:return)

      assert_no_text groups(:group_a).name
      assert_text groups(:group_b).name

      #   Test empty state
      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: 'z6z6z6'
      find('input.t-search-component').native.send_keys(:return)
      assert_text I18n.t(:'dashboard.groups.index.no_groups_description')
    end

    test 'filtering renders flat list' do
      group1 = groups(:group_one)
      group3 = groups(:group_three)
      login_as users(:john_doe)
      visit dashboard_groups_url

      within('#groups_tree') do
        within("#group_#{group1.id}") do
          assert_text group1.name
          assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
        end

        within("#group_#{group3.id}") do
          assert_text group3.name
          assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
        end
      end

      fill_in I18n.t(:'dashboard.groups.index.search.placeholder'), with: 'group'
      find('input.t-search-component').native.send_keys(:return)

      within('#groups_tree') do
        assert_text group1.name
        assert_text group3.name
        assert_no_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
      end
    end

    test 'should update samples count after a group deletion' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      visit group_url(@subgroup12aa)
      click_on I18n.t('groups.sidebar.settings')
      click_link I18n.t('groups.sidebar.general')

      assert_selector 'h2', text: I18n.t('groups.sidebar.general')

      assert_selector 'a', text: I18n.t('groups.edit.advanced.delete.submit'), count: 1
      click_link I18n.t('groups.edit.advanced.delete.submit')

      assert_text I18n.t('groups.edit.advanced.delete.confirm')
      assert_button I18n.t('components.confirmation.confirm')
      click_button I18n.t('components.confirmation.confirm')

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 2, @group12.reload.samples_count
      assert_equal 1, @subgroup12a.reload.samples_count
      assert_equal 1, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a group transfer' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      visit group_url(@subgroup12aa)

      click_on I18n.t('groups.sidebar.settings')
      click_link I18n.t('groups.sidebar.general')

      assert_selector 'h2', text: I18n.t('groups.edit.advanced.transfer.title')
      within %(form[action="/group-12/subgroup-12-a/subgroup-12-a-a/transfer"]) do
        assert_selector 'input[type=submit]:disabled'
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{@subgroup12b.full_path}']").click
        assert_selector 'input[type=submit]:not(:disabled)'
        click_on I18n.t('groups.edit.advanced.transfer.submit')
      end

      within('#turbo-confirm') do
        assert_text I18n.t('components.confirmation.title')
        fill_in I18n.t('components.confirmation.confirm_label'), with: @subgroup12aa.path
        click_on I18n.t('components.confirmation.confirm')
      end

      assert_text I18n.t('groups.transfer.success')

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 4, @group12.reload.samples_count
      assert_equal 1, @subgroup12a.reload.samples_count
      assert_equal 3, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a project deletion' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      project31 = projects(:project31)
      visit project_edit_path(project31)
      assert_selector 'a', text: I18n.t(:'projects.edit.advanced.destroy.submit'), count: 1
      click_link I18n.t(:'projects.edit.advanced.destroy.submit')

      assert_text I18n.t('projects.edit.advanced.destroy.confirm')
      assert_button I18n.t('components.confirmation.confirm')
      click_button I18n.t('components.confirmation.confirm')

      assert_text I18n.t(:'projects.destroy.success', project_name: project31.name)

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 2, @group12.reload.samples_count
      assert_equal 1, @subgroup12a.reload.samples_count
      assert_equal 1, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a project transfer' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      project31 = projects(:project31)
      visit project_edit_path(project31)
      assert_selector 'h2', text: I18n.t('projects.edit.advanced.transfer.title')
      within %(form[action="/group-12/subgroup-12-a/subgroup-12-a-a/project-31/-/transfer"]) do
        assert_selector 'input[type=submit]:disabled'
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{@subgroup12b.full_path}']").click
        assert_selector 'input[type=submit]:not(:disabled)'
        click_on I18n.t('projects.edit.advanced.transfer.submit')
      end

      within('#turbo-confirm') do
        assert_text I18n.t('components.confirmation.title')
        fill_in I18n.t('components.confirmation.confirm_label'), with: project31.name
        click_on I18n.t('components.confirmation.confirm')
      end

      assert_text I18n.t('projects.transfer.success')

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 4, @group12.reload.samples_count
      assert_equal 1, @subgroup12a.reload.samples_count
      assert_equal 3, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a sample deletion' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      project29 = projects(:project29)
      sample32 = samples(:sample32)
      visit namespace_project_sample_url(@subgroup12a, project29, sample32)
      click_link I18n.t('projects.samples.show.remove_button')

      within('#turbo-confirm[open]') do
        click_button I18n.t(:'components.confirmation.confirm')
      end

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 3, @group12.reload.samples_count
      assert_equal 2, @subgroup12a.reload.samples_count
      assert_equal 1, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a sample creation' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      project31 = projects(:project31)
      visit namespace_project_samples_url(@subgroup12aa, project31)

      click_link I18n.t('projects.samples.index.new_button')

      find('input#sample_name').fill_in with: 'Test Sample'
      click_button I18n.t('projects.samples.new.submit_button')

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 5, @group12.reload.samples_count
      assert_equal 4, @subgroup12a.reload.samples_count
      assert_equal 1, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a sample transfer' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      project31 = projects(:project31)
      project30 = projects(:project30)
      sample34 = samples(:sample34)
      visit namespace_project_samples_url(@subgroup12aa, project31)

      find("input[type='checkbox'][id='sample_#{sample34.id}']").click
      click_link I18n.t('projects.samples.index.transfer_button')

      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.transfers.dialog.description.singular')
        within %(turbo-frame[id="list_selections"]) do
          assert_text sample34.name
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project30.full_path}']").click
        click_on I18n.t('projects.samples.transfers.dialog.submit_button')
      end

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 4, @group12.reload.samples_count
      assert_equal 2, @subgroup12a.reload.samples_count
      assert_equal 2, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end

    test 'should update samples count after a sample clone' do
      login_as users(:john_doe)
      visit dashboard_groups_url

      assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_equal 4, @group12.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      project31 = projects(:project31)
      project30 = projects(:project30)
      sample34 = samples(:sample34)
      visit namespace_project_samples_url(@subgroup12aa, project31)

      find("input[type='checkbox'][id='sample_#{sample34.id}']").click
      click_link I18n.t('projects.samples.index.clone_button')

      within('span[data-controller-connected="true"] dialog') do
        assert_text I18n.t('projects.samples.clones.dialog.description.singular')
        within %(turbo-frame[id="list_selections"]) do
          assert_text sample34.name
        end
        find('input#select2-input').click
        find("button[data-viral--select2-primary-param='#{project30.full_path}']").click
        click_on I18n.t('projects.samples.clones.dialog.submit_button')
      end
      assert_text I18n.t('projects.samples.clones.create.success')

      visit dashboard_groups_url
      within("li#group_#{@group12.id}") do
        find('a.folder-toggle-wrap').click
      end

      assert_equal 5, @group12.reload.samples_count
      assert_equal 3, @subgroup12a.reload.samples_count
      assert_equal 2, @subgroup12b.reload.samples_count

      within("#group_#{@group12.id}-samples-count") do
        assert_text @group12.samples_count
      end

      within("#group_#{@subgroup12a.id}-samples-count") do
        assert_text @subgroup12a.samples_count
      end

      within("#group_#{@subgroup12b.id}-samples-count") do
        assert_text @subgroup12b.samples_count
      end
    end
  end
end
