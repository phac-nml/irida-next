# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    @groups_count = @user.groups.self_and_descendant_ids.count
    login_as @user
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
      fill_in 'Description', with: 'New sub-group description'
      click_on I18n.t('groups.new_subgroup.submit')
    end

    assert_text I18n.t('groups.create.success')
    assert_selector 'h1', text: 'New sub-group'
  end

  test 'show error when creating a sub-group with a same name' do
    visit group_url(groups(:group_one))
    assert_link text: I18n.t('groups.show.create_subgroup_button'), count: 1
    click_link I18n.t('groups.show.create_subgroup_button')

    subgroup1 = groups(:subgroup1)

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: subgroup1.name
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

    within all('form[action="/group-1"]')[0] do
      fill_in I18n.t('activerecord.attributes.group.name'), with: group_name
      fill_in I18n.t('activerecord.attributes.group.description'), with: group_description
      click_on I18n.t('groups.edit.details.submit')
    end

    assert_text I18n.t('groups.update.success', group_name:)

    within %(turbo-frame[id="group_name_and_description_form"]) do
      assert_field I18n.t('activerecord.attributes.group.name'), with: group_name
      assert_field I18n.t('activerecord.attributes.group.description'), with: group_description
    end

    within '#sidebar' do
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
    within %(div[data-controller="transfer"][data-controller-connected="true"]) do
      within %(form[action="/group-1/transfer"]) do
        assert_selector 'input[type=submit]:disabled'
        find('#new_namespace_id').find("option[value='#{group3.id}']").select_option
        assert_selector 'input[type=submit]:not(:disabled)'
        click_on I18n.t('groups.edit.advanced.transfer.submit')
      end
    end

    within('#turbo-confirm') do
      assert_text I18n.t('components.confirmation.title')
      fill_in I18n.t('components.confirmation.confirm_label'), with: group1.path
      click_on I18n.t('components.confirmation.confirm')
    end

    assert_text I18n.t('groups.transfer.success')
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
    assert_selector 'li.namespace-entry', count: 21

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
end
