# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase # rubocop:disable Metrics/ClassLength
  def setup
    @user = users(:john_doe)
    @groups_count = @user.groups.self_and_descendant_ids.count
    login_as @user
  end

  test 'can create a group' do
    visit groups_url

    click_button I18n.t(:'general.navbar.new_dropdown.aria_label')
    click_link I18n.t(:'general.navbar.new_dropdown.group')

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

  test 'can create a sub-group' do
    visit group_url(groups(:group_one))

    assert_selector 'a', text: I18n.t(:'groups.show.create_subgroup_button'), count: 1
    click_link I18n.t(:'groups.show.create_subgroup_button')

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t(:'activerecord.attributes.group.name'), with: 'New sub-group'
      fill_in 'Description', with: 'New sub-group description'
      click_on I18n.t(:'groups.new_subgroup.submit')
    end

    assert_text I18n.t(:'groups.create.success')
    assert_selector 'h1', text: 'New sub-group'
  end

  test 'can edit a group' do
    visit group_url(groups(:group_one))

    click_link I18n.t(:'groups.sidebar.settings')

    within all('form[action="/group-1"]')[0] do
      fill_in I18n.t(:'activerecord.attributes.group.name'), with: 'Edited group'

      fill_in 'Description', with: 'Edited group description'
      click_on I18n.t(:'groups.edit.details.submit')
    end

    assert_text I18n.t(:'groups.update.success')
    assert_selector 'h1', text: 'Edited group'
  end

  test 'can edit a group path' do
    visit group_url(groups(:group_one))

    click_link I18n.t(:'groups.sidebar.settings')

    within all('form[action="/group-1"]')[1] do
      fill_in I18n.t(:'activerecord.attributes.group.path'), with: 'group-1-edited'

      click_on I18n.t(:'groups.edit.advanced.path.submit')
    end

    assert_text I18n.t(:'groups.update.success')
    assert_current_path '/group-1-edited'
  end

  test 'can delete a group' do
    visit dashboard_groups_path
    assert_text groups(:group_two).name

    find('div.title a', text: groups(:group_two).name).click

    click_link I18n.t(:'groups.sidebar.settings')

    assert_selector 'a', text: I18n.t(:'groups.edit.advanced.delete.submit'), count: 1
    click_link I18n.t(:'groups.edit.advanced.delete.submit')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'h1', text: I18n.t(:'dashboard.groups.index.title')
    assert_no_text groups(:group_two).name
  end

  test 'can transfer a group' do
    group1 = groups(:group_one)
    group3 = groups(:group_three)
    visit group_url(group1)

    click_link I18n.t(:'groups.sidebar.settings')
    assert_selector 'h2', text: I18n.t(:'groups.edit.advanced.transfer.title')

    within %(form[action="/group-1/transfer"]) do
      find('#new_namespace_id').find("option[value='#{group3.id}']").select_option
      click_on I18n.t(:'groups.edit.advanced.transfer.submit')
    end

    within('#turbo-confirm') do
      assert_text I18n.t(:'components.confirmation.title')
      find('input[type=text]').fill_in with: group1.path
      click_on I18n.t(:'components.confirmation.confirm')
    end

    assert_text I18n.t(:'groups.transfer.success')
  end

  test 'user with maintainer access should not be able to see the transfer group section' do
    login_as users(:joan_doe)

    visit group_url(groups(:group_one))

    click_link I18n.t(:'groups.sidebar.settings')

    assert_selector 'h3', text: I18n.t(:'groups.edit.advanced.transfer.title'), count: 0
  end

  test 'cannot transfer group into same namespace' do
    group = groups(:group_one)
    visit group_url(group)

    click_link I18n.t(:'groups.sidebar.settings')
    assert_selector 'h2', text: I18n.t(:'groups.edit.advanced.transfer.title')

    within %(form[action="/group-1/transfer"]) do
      find('#new_namespace_id').find("option[value='#{group.id}']").select_option
      click_on I18n.t(:'groups.edit.advanced.transfer.submit')
    end

    within('#turbo-confirm') do
      assert_text I18n.t(:'components.confirmation.title')
      find('input[type=text]').fill_in with: group.path
      click_on I18n.t(:'components.confirmation.confirm')
    end

    assert_text I18n.t(:'services.groups.transfer.same_group_and_namespace')
  end

  test 'cannot create subgroup' do
    login_as users(:ryan_doe)

    visit group_url(groups(:group_one))

    assert_selector 'a', text: I18n.t(:'groups.show.create_subgroup_button'), count: 0
  end

  test 'cannot see settings' do
    login_as users(:ryan_doe)
    visit group_url(groups(:group_one))

    assert_selector 'a', text: I18n.t(:'groups.sidebar.settings'), count: 0
  end

  test 'can view settings but cannot delete a group' do
    login_as users(:joan_doe)
    visit group_url(groups(:group_one))

    click_link I18n.t(:'groups.sidebar.settings')

    assert_selector 'a', text: I18n.t(:'groups.edit.advanced.delete.submit'), count: 0
  end

  test 'can view group' do
    visit group_url(groups(:group_one))

    assert_selector 'h1', text: 'Group 1'
  end

  test 'can not view group' do
    group = groups(:david_doe_group_four)
    visit group_url(group)

    assert_text I18n.t(:'action_policy.policy.group.read?', name: group.name)
  end
end
