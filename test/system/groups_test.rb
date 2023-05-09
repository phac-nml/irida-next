# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    @groups_count = @user.groups.self_and_descendant_ids.count
    login_as @user
  end

  test 'can see the list of groups' do
    visit groups_url

    assert_selector 'h1', text: I18n.t(:'groups.show.title')
    assert_selector 'tr', count: @groups_count
    assert_text groups(:group_one).name
    assert_text groups(:subgroup1).name
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

  test 'can create a group from listing page' do
    visit groups_url

    click_link I18n.t(:'groups.index.create_group_button')

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

    within %(div[data-controller="slugify"][data-controller-connected="true"]) do
      fill_in I18n.t(:'activerecord.attributes.group.name'), with: 'Edited group'

      assert_selector %(input[data-slugify-target="path"]) do |input|
        assert_equal 'edited-group', input['value']
      end

      fill_in 'Description', with: 'Edited group description'
      click_on I18n.t(:'groups.edit.details.submit')
    end

    assert_text I18n.t(:'groups.update.success')
    assert_selector 'h1', text: 'Edited group'
  end

  test 'can delete a group' do
    visit group_url(groups(:group_two))

    click_link I18n.t(:'groups.sidebar.settings')

    assert_selector 'a', text: I18n.t(:'groups.edit.advanced.delete_group.submit'), count: 1

    accept_alert do
      click_link I18n.t(:'groups.edit.advanced.delete_group.submit')
    end

    assert_selector 'h1', text: I18n.t(:'groups.show.title')
    assert_selector 'tr', count: @groups_count - 1
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

    assert_selector 'a', text: I18n.t(:'groups.edit.advanced.delete_group.submit'), count: 0
  end
end
