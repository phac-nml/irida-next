# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    @groups_count = @user.groups.self_and_descendant_ids.count
    @group12 = groups(:group_twelve)
    @subgroup12a = groups(:subgroup_twelve_a)
    @subgroup12aa = groups(:subgroup_twelve_a_a)
    @subgroup12b = groups(:subgroup_twelve_b)
    @group6 = groups(:group_six)
    @subgroup2 = groups(:subgroup2)
    @project31 = projects(:project31)
    @project30 = projects(:project30)
    @sample34 = samples(:sample34)
    login_as @user

    Sample.reindex
    Searchkick.enable_callbacks
  end

  def teardown
    Searchkick.disable_callbacks
  end

  test 'can create a group' do
    visit groups_url

    click_button I18n.t('general.navbar.new_dropdown.aria_label')
    click_link I18n.t('general.navbar.new_dropdown.group')

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New group'
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New group description'
      click_on I18n.t('groups.create.submit')
    end

    assert_text I18n.t('groups.create.success')
    assert_selector 'h1', text: 'New group'
  end

  test 'show error when creating a group with a short name' do
    visit new_group_url

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'a'
      fill_in I18n.t('activerecord.attributes.group.path'), with: 'new-group'
      click_on I18n.t('groups.create.submit')
    end

    assert_text 'Group name is too short'
    assert_current_path '/-/groups/new'
  end

  test 'show error when creating a group with a same name' do
    group2 = groups(:group_two)
    visit new_group_url

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: group2.name
      click_on I18n.t('groups.create.submit')
    end

    assert_text 'Group name has already been taken'
    assert_current_path '/-/groups/new'
  end

  test 'show error when creating a group with a long description' do
    visit new_group_url

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New group'
      fill_in I18n.t('activerecord.attributes.group.description'), with: 'a' * 256
      click_on I18n.t('groups.create.submit')
    end

    assert_text 'Description is too long'
    assert_current_path '/-/groups/new'
  end

  test 'show error when creating a group with a same path' do
    group2 = groups(:group_two)
    visit new_group_url

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New group'
      fill_in I18n.t('activerecord.attributes.group.path'), with: group2.path
      click_on I18n.t('groups.create.submit')
    end

    assert_text 'Path has already been taken'
    assert_current_path '/-/groups/new'
  end

  test 'can create a sub-group' do
    visit group_url(groups(:group_one))
    assert_link text: I18n.t('groups.show.create_subgroup_button'), count: 1
    click_link I18n.t('groups.show.create_subgroup_button')

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New sub-group'
      fill_in I18n.t('groups.new_subgroup.select_group'), with: '1'
      click_on 'INXT_GRP_AAAAAAAAAA'
      fill_in 'Description', with: 'New sub-group description'
      click_on I18n.t('groups.new_subgroup.submit')
    end

    assert_text I18n.t('groups.create.success')
    assert_selector 'h1', text: 'New sub-group'
  end

  test 'should have Group URL filled with parent group, when creating new sub-group' do
    group1 = groups(:group_one)
    visit group_url(group1)
    click_link I18n.t('groups.show.create_subgroup_button')

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      assert_selector %(input[data-viral--select2-target="input"]) do |input|
        assert_equal group1.path, input['value']
      end
    end
  end

  test 'show error when creating a sub-group with a same name' do
    visit group_url(groups(:group_one))
    assert_link text: I18n.t('groups.show.create_subgroup_button'), count: 1
    click_link I18n.t('groups.show.create_subgroup_button')

    subgroup1 = groups(:subgroup1)

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: subgroup1.name
      fill_in I18n.t('groups.new_subgroup.select_group'), with: '1'
      click_on 'INXT_GRP_AAAAAAAAAA'
      click_on I18n.t('groups.new_subgroup.submit')
    end

    assert_text 'Group name has already been taken'
  end

  test 'show error when creating a sub-group with a same path' do
    visit group_url(groups(:group_one))
    assert_link text: I18n.t('groups.show.create_subgroup_button'), count: 1
    click_link I18n.t('groups.show.create_subgroup_button')

    subgroup1 = groups(:subgroup1)

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New group'
      fill_in I18n.t('activerecord.attributes.group.path'), with: subgroup1.path
      fill_in I18n.t('groups.new_subgroup.select_group'), with: '1'
      click_on 'INXT_GRP_AAAAAAAAAA'
      click_on I18n.t('groups.new_subgroup.submit')
    end

    assert_text 'Path has already been taken'
  end

  test 'can edit a group' do
    group_name = 'Edited group'
    group_description = 'Edited group description'
    visit group_url(groups(:group_one))

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    fill_in I18n.t('activerecord.attributes.group.name'), with: group_name
    fill_in I18n.t('activerecord.attributes.group.description'), with: group_description
    click_on I18n.t('groups.edit.details.submit')

    assert_text I18n.t('groups.update.success', group_name:)

    within %(turbo-frame[id="group_name_and_description_form"]) do
      assert_field I18n.t('activerecord.attributes.group.name'), with: group_name
      assert_field I18n.t('activerecord.attributes.group.description'), with: group_description
    end

    within 'aside#sidebar' do
      assert_text group_name
    end

    within '#breadcrumb' do
      assert_text group_name
    end
  end

  test 'can edit a group path' do
    group1 = groups(:group_one)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    fill_in I18n.t('activerecord.attributes.group.path'), with: 'group-1-edited'
    click_on I18n.t('groups.edit.advanced.path.submit')

    assert_text I18n.t('groups.update.success', group_name: group1.name)
    assert_current_path '/-/groups/group-1-edited/-/edit'
  end

  test 'show error when editing a group with a short name' do
    group1 = groups(:group_one)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    fill_in I18n.t('activerecord.attributes.group.name'), with: 'a'
    click_on I18n.t('groups.edit.details.submit')

    within '#sidebar' do
      assert_text group1.name
    end

    within '#breadcrumb' do
      assert_text group1.name
    end

    assert_text 'Group name is too short'
    assert_current_path '/-/groups/group-1/-/edit'
  end

  test 'show error when editing a group with a same name' do
    group1 = groups(:group_one)
    group2 = groups(:group_two)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    fill_in I18n.t('activerecord.attributes.group.name'), with: group2.name
    click_on I18n.t('groups.edit.details.submit')

    within '#sidebar' do
      assert_text group1.name
    end

    within '#breadcrumb' do
      assert_text group1.name
    end

    assert_text 'Group name has already been taken'
    assert_current_path '/-/groups/group-1/-/edit'
  end

  test 'show error when editing a group with a long description' do
    group1 = groups(:group_one)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    fill_in I18n.t('activerecord.attributes.group.description'), with: 'a' * 256
    click_on I18n.t('groups.edit.details.submit')

    within '#sidebar' do
      assert_text group1.name
    end

    within '#breadcrumb' do
      assert_text group1.name
    end

    assert_text 'Description is too long'
    assert_current_path '/-/groups/group-1/-/edit'
  end

  test 'show error when editing a group with a same path' do
    group1 = groups(:group_one)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    group2 = groups(:group_two)

    fill_in I18n.t('activerecord.attributes.group.path'), with: group2.path
    click_on I18n.t('groups.edit.advanced.path.submit')

    within '#sidebar' do
      assert_text group1.name
    end

    within '#breadcrumb' do
      assert_text group1.name
    end

    assert_text 'Path has already been taken'
    assert_current_path '/-/groups/group-1/-/edit'
  end

  test 'can delete a group' do
    group2 = groups(:group_two)
    visit group_url(group2)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    assert_selector 'h2', text: I18n.t('groups.sidebar.general')

    assert_selector 'a', text: I18n.t('groups.edit.advanced.delete.submit'), count: 1
    click_link I18n.t('groups.edit.advanced.delete.submit')

    assert_text I18n.t('groups.edit.advanced.delete.confirm')
    assert_button I18n.t('components.confirmation.confirm')
    click_button I18n.t('components.confirmation.confirm')

    assert_selector 'h1', text: I18n.t('dashboard.groups.index.title')
    assert_no_text groups(:group_two).name
  end

  test 'can transfer a group' do
    group1 = groups(:group_one)
    group3 = groups(:group_three)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    assert_selector 'h2', text: I18n.t('groups.edit.advanced.transfer.title')
    within %(form[action="/group-1/transfer"]) do
      assert_selector 'input[type=submit]:disabled'
      find('input#select2-input').click
      find("button[data-viral--select2-primary-param='#{group3.full_path}']").click
      assert_selector 'input[type=submit]:not(:disabled)'
      click_on I18n.t('groups.edit.advanced.transfer.submit')
    end

    within('#turbo-confirm') do
      assert_text I18n.t('components.confirmation.title')
      fill_in I18n.t('components.confirmation.confirm_label'), with: group1.path
      click_on I18n.t('components.confirmation.confirm')
    end

    assert_text I18n.t('groups.transfer.success')
  end

  test 'empty state of transfer group' do
    group1 = groups(:group_one)
    visit group_url(group1)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    assert_selector 'h2', text: I18n.t('groups.edit.advanced.transfer.title')
    within %(form[action="/group-1/transfer"]) do
      find('input#select2-input').fill_in with: 'invalid project name or puid'
      assert_text I18n.t(:'groups.edit.advanced.transfer.empty_state')
    end
  end

  test 'user with maintainer access should not be able to see the transfer group section' do
    login_as users(:joan_doe)

    visit group_url(groups(:group_one))

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    assert_selector 'h3', text: I18n.t('groups.edit.advanced.transfer.title'), count: 0
  end

  test 'cannot transfer group into same namespace' do
    group = groups(:group_one)
    visit group_url(group)

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    assert_selector 'h2', text: I18n.t('groups.edit.advanced.transfer.title')

    within %(form[action="/group-1/transfer"]) do
      assert_no_selector "option[value='#{group.id}']"
    end
  end

  test 'cannot create subgroup' do
    login_as users(:ryan_doe)

    visit group_url(groups(:group_one))

    assert_selector 'a', text: I18n.t('groups.show.create_subgroup_button'), count: 0
  end

  test 'cannot see settings' do
    login_as users(:ryan_doe)
    visit group_url(groups(:group_one))

    assert_selector 'a', text: I18n.t('groups.sidebar.settings'), count: 0
  end

  test 'can view settings but cannot delete a group' do
    login_as users(:joan_doe)
    visit group_url(groups(:group_one))

    click_on I18n.t('groups.sidebar.settings')
    click_link I18n.t('groups.sidebar.general')

    assert_selector 'a', text: I18n.t('groups.edit.advanced.delete.submit'), count: 0
  end

  test 'can view group' do
    visit group_url(groups(:group_one))

    assert_selector 'h1', text: 'Group 1'
  end

  test 'can not view group' do
    login_as users(:user_no_access)
    group = groups(:david_doe_group_four)
    visit group_url(group)

    assert_text I18n.t('action_policy.policy.group.read?', name: group.name)
  end

  test 'visiting the show' do
    @group = groups(:group_one)
    visit group_url(@group)
    assert_selector 'h1', text: @group.name

    assert_selector 'a.active', text: I18n.t(:'groups.show.tabs.subgroups_and_projects')
    assert_selector 'li.namespace-entry', count: 20
    click_on I18n.t(:'components.pagination.next')
    assert_selector 'li.namespace-entry', count: 1

    click_on I18n.t(:'groups.show.tabs.shared_namespaces')
    assert_selector 'a.active', text: I18n.t(:'groups.show.tabs.shared_namespaces')
    assert_selector 'div.namespace-entry-contents', count: 1
  end

  test 'displays empty shared namespaces' do
    @group = groups(:group_eight)
    visit group_url(@group)
    click_on I18n.t(:'groups.show.tabs.shared_namespaces')
    assert_selector 'div.namespace-entry-contents', count: 0
    assert_text I18n.t('groups.show.shared_namespaces.no_shared.title')
  end

  test 'search subgroups and projects' do
    @group = groups(:group_one)
    visit group_url(@group)
    assert_text I18n.t(:'components.pagination.next')
    fill_in I18n.t('groups.show.search.placeholder'), with: 'project 2'
    find('input.t-search-component').native.send_keys(:return)

    assert_selector 'li.namespace-entry', count: 5
  end

  test 'filtering renders flat list for subgroups and projects' do
    group12 = groups(:group_twelve)
    subgroup12a = groups(:subgroup_twelve_a)
    subgroup12b = groups(:subgroup_twelve_b)
    subgroup12aa = groups(:subgroup_twelve_a_a)

    visit group_url(group12)

    within('div.namespace-tree-container') do
      assert_selector 'li', count: 2
      within("#group_#{subgroup12a.id}") do
        assert_text subgroup12a.name
        assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
      end

      within("#group_#{subgroup12b.id}") do
        assert_text subgroup12b.name
        assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
      end

      assert_no_text subgroup12aa.name
    end

    fill_in I18n.t('groups.show.search.placeholder'), with: 'subgroup'
    find('input.t-search-component').native.send_keys(:return)

    within('div.namespace-tree-container') do
      assert_selector 'li', count: 3
      assert_text subgroup12a.name
      assert_text subgroup12b.name
      assert_text subgroup12aa.name
      assert_no_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
    end
  end

  test 'should update samples count after a group deletion' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
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

    assert_selector 'h1', text: I18n.t('dashboard.groups.index.title')

    assert_equal 1, @subgroup12a.reload.samples_count
    assert_equal 1, @subgroup12b.reload.samples_count

    visit group_url(@group12)

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end
  end

  test 'should update samples count after a group transfer' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
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

    visit group_url(@group12)
    within("li#group_#{@subgroup12b.id}") do
      find('a.folder-toggle-wrap').click
    end

    assert_equal 1, @subgroup12a.reload.samples_count
    assert_equal 2, @subgroup12aa.reload.samples_count
    assert_equal 3, @subgroup12b.reload.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end
  end

  test 'should update samples count after a project deletion' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    project31 = projects(:project31)
    visit project_edit_path(project31)
    assert_selector 'a', text: I18n.t(:'projects.edit.advanced.destroy.submit'), count: 1
    click_link I18n.t(:'projects.edit.advanced.destroy.submit')

    assert_text I18n.t('projects.edit.advanced.destroy.confirm')
    assert_button I18n.t('components.confirmation.confirm')
    click_button I18n.t('components.confirmation.confirm')

    assert_text I18n.t(:'projects.destroy.success', project_name: project31.name)

    visit group_url(@group12)
    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end

    assert_equal 1, @subgroup12a.reload.samples_count
    assert_equal 0, @subgroup12aa.reload.samples_count
    assert_equal 1, @subgroup12b.reload.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end
  end

  test 'should update samples count after a project transfer' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
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

    visit group_url(@group12)
    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end

    assert_equal 1, @subgroup12a.reload.samples_count
    assert_equal 0, @subgroup12aa.reload.samples_count
    assert_equal 3, @subgroup12b.reload.samples_count

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end
  end

  test 'should update samples count after a sample deletion' do
    project29 = projects(:project29)
    sample32 = samples(:sample32)

    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count
    assert_equal 1, project29.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{project29.id}-samples-count") do
      assert_text project29.samples.size
    end

    visit namespace_project_sample_url(@subgroup12a, project29, sample32)
    click_link I18n.t('projects.samples.show.remove_button')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    visit group_url(@group12)
    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end

    assert_equal 2, @subgroup12a.reload.samples_count
    assert_equal 2, @subgroup12aa.reload.samples_count
    assert_equal 1, @subgroup12b.reload.samples_count
    assert_equal 0, project29.reload.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{project29.id}-samples-count") do
      assert_text project29.samples.size
    end
  end

  test 'should update samples count after a sample creation' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @subgroup12aa.puid

    within("li#group_#{@subgroup12aa.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project31.puid

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count
    assert_equal 2, @project31.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{@project31.id}-samples-count") do
      assert_text @project31.samples.size
    end

    visit namespace_project_samples_url(@subgroup12aa, @project31)

    click_link I18n.t('projects.samples.index.new_button')

    find('input#sample_name').fill_in with: 'Test Sample'
    click_button I18n.t('projects.samples.new.submit_button')

    visit group_url(@group12)

    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @subgroup12aa.puid

    within("li#group_#{@subgroup12aa.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project31.puid

    assert_equal 4, @subgroup12a.reload.samples_count
    assert_equal 3, @subgroup12aa.reload.samples_count
    assert_equal 1, @subgroup12b.reload.samples_count
    assert_equal 3, @project31.reload.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{@project31.id}-samples-count") do
      assert_text @project31.samples.size
    end
  end

  test 'should update samples count after a sample transfer' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @subgroup12aa.puid

    within("li#group_#{@subgroup12aa.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project31.puid

    within("li#group_#{@subgroup12b.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project30.puid

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count
    assert_equal 2, @project31.samples.size
    assert_equal 1, @project30.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{@project31.id}-samples-count") do
      assert_text @project31.samples.size
    end

    within("#project_#{@project30.id}-samples-count") do
      assert_text @project30.samples.size
    end

    visit namespace_project_samples_url(@subgroup12aa, @project31)

    find("input[type='checkbox'][id='sample_#{@sample34.id}']").click
    click_link I18n.t('projects.samples.index.transfer_button')

    within('span[data-controller-connected="true"] dialog') do
      assert_text I18n.t('projects.samples.transfers.dialog.description.singular')
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample34.name
      end
      find('input#select2-input').click
      find("button[data-viral--select2-primary-param='#{@project30.full_path}']").click
      click_on I18n.t('projects.samples.transfers.dialog.submit_button')
    end

    visit group_url(@group12)
    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @subgroup12aa.puid

    within("li#group_#{@subgroup12aa.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project31.puid

    within("li#group_#{@subgroup12b.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project30.puid

    assert_equal 2, @subgroup12a.reload.samples_count
    assert_equal 1, @subgroup12aa.reload.samples_count
    assert_equal 2, @subgroup12b.reload.samples_count
    assert_equal 1, @project31.reload.samples.size
    assert_equal 2, @project30.reload.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{@project31.id}-samples-count") do
      assert_text @project31.samples.size
    end

    within("#project_#{@project30.id}-samples-count") do
      assert_text @project30.samples.size
    end
  end

  test 'should update samples count after a sample clone' do
    visit group_url(@group12)

    assert_selector 'h1', text: @group12.name

    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @subgroup12aa.puid

    within("li#group_#{@subgroup12aa.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project31.puid

    within("li#group_#{@subgroup12b.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project30.puid

    assert_equal 3, @subgroup12a.samples_count
    assert_equal 1, @subgroup12b.samples_count
    assert_equal 2, @project31.samples.size
    assert_equal 1, @project30.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{@project31.id}-samples-count") do
      assert_text @project31.samples.size
    end

    within("#project_#{@project30.id}-samples-count") do
      assert_text @project30.samples.size
    end

    visit namespace_project_samples_url(@subgroup12aa, @project31)

    find("input[type='checkbox'][id='sample_#{@sample34.id}']").click
    click_link I18n.t('projects.samples.index.clone_button')

    within('span[data-controller-connected="true"] dialog') do
      assert_text I18n.t('projects.samples.clones.dialog.description.singular')
      within %(turbo-frame[id="list_selections"]) do
        assert_text @sample34.name
      end
      find('input#select2-input').click
      find("button[data-viral--select2-primary-param='#{@project30.full_path}']").click
      click_on I18n.t('projects.samples.clones.dialog.submit_button')
    end
    assert_text I18n.t('projects.samples.clones.create.success')

    visit group_url(@group12)

    within("li#group_#{@subgroup12a.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @subgroup12aa.puid

    within("li#group_#{@subgroup12aa.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project31.puid

    assert_no_selector "#project_#{@project30.id}-samples-count"

    within("li#group_#{@subgroup12b.id}") do
      find('a.folder-toggle-wrap').click
    end
    assert_text @project30.puid

    assert_equal 3, @subgroup12a.reload.samples_count
    assert_equal 2, @subgroup12aa.reload.samples_count
    assert_equal 2, @subgroup12b.reload.samples_count
    assert_equal 2, @project31.reload.samples.size
    assert_equal 2, @project30.reload.samples.size

    within("#group_#{@subgroup12a.id}-samples-count") do
      assert_text @subgroup12a.samples_count
    end

    within("#group_#{@subgroup12aa.id}-samples-count") do
      assert_text @subgroup12aa.samples_count
    end

    within("#group_#{@subgroup12b.id}-samples-count") do
      assert_text @subgroup12b.samples_count
    end

    within("#project_#{@project31.id}-samples-count") do
      assert_text @project31.samples.size
    end

    within("#project_#{@project30.id}-samples-count") do
      assert_text @project30.samples.size
    end
  end

  test 'filter shared groups and projects by puid' do
    subgroup3 = groups(:subgroup3)
    visit group_url(@group6)

    click_on I18n.t(:'groups.show.tabs.shared_namespaces')

    within('div.namespace-tree-container') do
      assert_selector 'li', count: 1
      within("#group_#{@subgroup2.id}") do
        assert_text @subgroup2.name
        assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
      end
      assert_no_text subgroup3.name
      assert_no_selector "li#group_#{subgroup3.id}"
    end

    input_field = find('input.t-search-component')
    input_field.fill_in with: subgroup3.puid
    input_field.native.send_keys(:return)

    within('div.namespace-tree-container') do
      assert_selector 'li', count: 1
      assert_text subgroup3.name
      assert_no_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
    end
  end

  test 'filtering renders flat list for shared groups and projects' do
    visit group_url(@group6)

    click_on I18n.t(:'groups.show.tabs.shared_namespaces')

    within('div.namespace-tree-container') do
      assert_selector 'li', count: 1
      within("#group_#{@subgroup2.id}") do
        assert_text @subgroup2.name
        assert_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
      end

      subgroup_num = 3
      8.times do
        assert_no_text "Subgroup #{subgroup_num}"
        subgroup_num += 1
      end
    end

    input_field = find('input.t-search-component')
    input_field.fill_in with: 'subgroup'
    input_field.native.send_keys(:return)

    within('div.namespace-tree-container') do
      assert_selector 'li', count: 9
      assert_text @subgroup2.name

      subgroup_num = 3
      8.times do
        assert_text "Subgroup #{subgroup_num}"
        subgroup_num += 1
      end

      assert_no_selector 'svg[class="Viral-Icon__Svg icon-chevron_right"]'
    end
  end

  test 'displays empty state result after filtering subgroups and projects' do
    visit group_url(@group6)

    assert_no_text I18n.t('groups.show.subgroups.no_subgroups.title')
    assert_no_text I18n.t('groups.show.subgroups.no_subgroups.description')

    input_field = find('input.t-search-component')
    input_field.fill_in with: 'invalid filter'
    input_field.native.send_keys(:return)

    assert_selector 'div.namespace-entry-contents', count: 0

    assert_text I18n.t('groups.show.subgroups.no_subgroups.title')
    assert_text I18n.t('groups.show.subgroups.no_subgroups.description')
  end

  test 'displays empty state result after filtering shared namespaces' do
    visit group_url(@group6)

    click_on I18n.t(:'groups.show.tabs.shared_namespaces')

    assert_no_text I18n.t('groups.show.shared_namespaces.no_shared.title')
    assert_no_text I18n.t('groups.show.shared_namespaces.no_shared.description')

    assert_text @subgroup2.puid

    assert_selector 'input.t-search-component'
    input_field = find('input.t-search-component')
    input_field.fill_in with: 'invalid filter'
    input_field.native.send_keys(:return)

    assert_selector 'div.namespace-entry-contents', count: 0
    assert_text I18n.t('groups.show.shared_namespaces.no_shared.title')
    assert_text I18n.t('groups.show.shared_namespaces.no_shared.description')
  end

  test 'should display a samples count that includes samples from shared groups and projects' do
    group_three = groups(:group_three)
    subgroup1 = groups(:subgroup1)
    visit group_url(group_three)

    assert_selector 'h1', text: group_three.name

    click_on I18n.t(:'groups.show.tabs.shared_namespaces')

    assert_equal 3, subgroup1.total_samples_count

    within("#group_#{subgroup1.id}-samples-count") do
      assert_text subgroup1.total_samples_count
    end
  end
end
