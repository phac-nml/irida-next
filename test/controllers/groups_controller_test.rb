# frozen_string_literal: true

require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in users(:john_doe)

    get groups_path
    assert_response :success
  end

  test 'should show the group' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_path(group)
    assert_response :success
  end

  test 'should display create new group page' do
    sign_in users(:john_doe)

    get new_group_path
    assert_response :success
  end

  test 'should create a new group' do
    sign_in users(:john_doe)

    assert_difference('Group.count') do
      post groups_path, params: { group: { name: 'New Group', path: 'new_group', description: 'This is a new group' } }
    end

    assert_redirected_to group_path(Group.last.full_path)
  end

  test 'should not create a new group with invalid params' do
    sign_in users(:john_doe)

    assert_no_difference('Group.count') do
      post groups_path, params: { group: { name: 'Ne', path: 'new_group', description: 'This is a new group' } }
    end

    assert_response :unprocessable_entity
  end

  test 'should update a group' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    patch group_path(group), params: { group: { name: 'New Group Name' } }
    assert_redirected_to group_path(group)
  end

  test 'should not update a group with invalid params' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    assert_no_changes -> { group.name } do
      patch group_path(group), params: { group: { name: 'NG' } }
    end
    assert_response :unprocessable_entity
  end

  test 'should show the sub group' do
    sign_in users(:john_doe)

    subgroup = groups(:subgroup1)
    get group_path(subgroup)
    assert_response :success
  end

  test 'should delete a group' do
    sign_in users(:john_doe)

    group = groups(:group_two)
    assert_difference('Group.count', -1) do
      delete group_path(group)
    end

    assert_redirected_to groups_path
  end

  test 'should not show a sub group that doesn\'t exist' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_path("#{group.full_path}/fakesubgroup")

    assert_response :not_found
  end

  test 'should not delete a group' do
    sign_in users(:joan_doe)

    group = groups(:group_one)
    assert_no_difference('Group.count') do
      delete group_path(group)
    end

    assert_response :unauthorized
  end

  test 'should create a new group and subgroup' do
    sign_in users(:john_doe)

    assert_difference('Group.count') do
      post groups_path, params: { group: { name: 'New Group', path: 'new_group', description: 'This is a new group' } }
    end

    assert_redirected_to group_path(Group.last.full_path)

    assert_difference('Group.count') do
      post groups_path,
           params: { group: { name: 'New Group', path:
           'new_group', description: 'This is a new group',
                              parent_id: Group.last.id } }
    end

    assert_redirected_to group_path(Group.last.full_path)
  end

  test 'should not create a subgroup' do
    sign_in users(:ryan_doe)
    group = groups(:group_one)

    post groups_path,
         params: { group: { name: 'New Group', path:
             'new_group', description: 'This is a new group',
                            parent_id: group.id } }

    assert_response :unauthorized
  end

  test 'should not show the group edit page' do
    sign_in users(:david_doe)
    group = groups(:group_one)

    get edit_group_path(group)

    assert_response :unauthorized
  end

  test 'should show the group edit page' do
    sign_in users(:john_doe)
    group = groups(:group_one)

    get edit_group_path(group)

    assert_response :success
  end

  test 'should share group b with group a' do
    sign_in users(:john_doe)
    group = groups(:group_one)
    namespace = groups(:group_six)

    post group_share_path(namespace,
                          params: { shared_group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST })

    assert_redirected_to group_path(namespace)
  end

  test 'should not share group b with group a as group b doesn\'t exist' do
    sign_in users(:john_doe)
    group_id = 1
    namespace = groups(:group_one)

    post group_share_path(namespace,
                          params: { shared_group_id: group_id,
                                    group_access_level: Member::AccessLevel::ANALYST })

    assert_response :unprocessable_entity
  end

  test 'shouldn\'t share group b with group a as user doesn\'t have correct permissions' do
    sign_in users(:micha_doe)
    group = groups(:group_one)
    namespace = groups(:group_six)

    post group_share_path(namespace,
                          params: { shared_group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST })

    assert_response :unauthorized
  end

  test 'group b already shared with group a' do
    sign_in users(:john_doe)
    group = groups(:group_one)
    namespace = groups(:group_six)

    post group_share_path(namespace,
                          params: { shared_group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST })

    assert_redirected_to group_path(namespace)

    post group_share_path(namespace,
                          params: { shared_group_id: group.id,
                                    group_access_level: Member::AccessLevel::ANALYST })

    assert_response :conflict
  end

  test 'unshare group' do
    sign_in users(:john_doe)
    namespace_group_link = namespace_group_links(:namespace_group_link2)
    group = namespace_group_link.group
    namespace = namespace_group_link.namespace

    post group_unshare_path(namespace, params: { shared_group_id: group.id })

    assert_redirected_to group_path(namespace)
  end

  test 'unshare group when link doesn\'t exist with another group' do
    sign_in users(:john_doe)
    group = groups(:group_one)
    namespace = groups(:group_six)

    post group_unshare_path(namespace, params: { shared_group_id: group.id })

    assert_response :unprocessable_entity
  end
end
