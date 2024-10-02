# frozen_string_literal: true

require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in users(:john_doe)

    get groups_path
    assert_response :redirect
  end

  test 'should show the group' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_path(group)
    assert_response :success
  end

  test 'should not show the group if member is expired' do
    sign_in users(:john_doe)

    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save
    group = groups(:group_one)
    get group_path(group)
    assert_response :unauthorized
  end

  test 'should not show the group if member is expired in linked group' do
    sign_in users(:david_doe)

    group_member = members(:group_four_member_david_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save
    group = groups(:david_doe_group_four)
    get group_path(group)
    assert_response :unauthorized
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
    patch group_path(group), params: { group: { name: 'New Group Name' }, format: :turbo_stream }
    assert_response :ok
  end

  test 'should not update a group with invalid params' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    assert_no_changes -> { group.name } do
      patch group_path(group), params: { group: { name: 'NG' }, format: :turbo_stream }
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

    assert_redirected_to dashboard_groups_path(format: :html)
  end

  test 'should not show a sub group that doesn\'t exist' do
    sign_in users(:john_doe)

    group = groups(:group_one)
    get group_path("#{group.full_path}/fakesubgroup")

    assert_response :not_found
  end

  test 'should not delete a group' do
    sign_in users(:joan_doe)

    group = groups(:group_twelve)
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

  test 'should transfer group' do
    sign_in users(:john_doe)
    group = groups(:group_twelve)
    new_namespace = groups(:group_two)

    put group_transfer_path(group),
        params: { new_namespace_id: new_namespace.id }, as: :turbo_stream

    assert_response :redirect
  end

  test 'should not create a new transfer with wrong parameters' do
    sign_in users(:john_doe)
    group = groups(:group_one)

    put group_transfer_path(group),
        params: { new_namespace_id: 'asdfasd' }, as: :turbo_stream

    assert_response :unprocessable_entity
  end

  test 'should not transfer a group without permission' do
    sign_in users(:joan_doe)
    group = groups(:group_one)
    new_namespace = groups(:group_two)

    put group_transfer_path(group),
        params: { new_namespace_id: new_namespace.id }, as: :turbo_stream

    assert_response :unauthorized
  end
end
