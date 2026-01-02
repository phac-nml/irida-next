# frozen_string_literal: true

require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john_doe)
    @group = groups(:group_one)
  end

  test 'should redirect index to dashboard_groups_url' do
    sign_in users(:john_doe)

    get groups_url
    assert_response :redirect
    assert_redirected_to dashboard_groups_url
  end

  test 'should get new' do
    sign_in users(:john_doe)

    get new_group_url
    assert_response :success
  end

  test 'should create group' do
    sign_in users(:john_doe)

    assert_difference('Group.count') do
      post groups_url, params: { group: { name: 'New Group', path: 'new_group' } }
    end

    assert_redirected_to group_url(Group.last)
  end

  test 'should not create group with invalid params' do
    sign_in users(:john_doe)

    assert_no_difference('Group.count') do
      post groups_path, params: { group: { name: 'Ne', path: 'new_group', description: 'This is a new group' } }
    end

    assert_response :unprocessable_content
  end

  test 'should create subgroup' do
    sign_in users(:john_doe)

    assert_difference('Group.count') do
      post groups_path,
           params: { group: { name: 'New Group', path:
           'new_group', description: 'This is a new group',
                              parent_id: @group.id } }
    end

    assert_redirected_to group_path(Group.last.full_path)
  end

  test 'should not create subgroup if user has insufficient permissions' do
    sign_in users(:ryan_doe)

    post groups_path,
         params: { group: { name: 'New Group', path:
             'new_group', description: 'This is a new group',
                            parent_id: @group.id } }

    assert_response :unauthorized
  end

  test 'should show group' do
    sign_in users(:john_doe)

    get group_url(@group)
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

  test 'should not show a group that doesn\'t exist' do
    sign_in users(:john_doe)

    get group_path("#{@group.full_path}/fakesubgroup")

    assert_response :not_found
  end

  test 'should get edit' do
    sign_in users(:john_doe)

    get edit_group_url(@group)
    assert_response :success
  end

  test 'should not get edit if user has insufficient permissions' do
    sign_in users(:david_doe)

    get edit_group_path(@group)

    assert_response :unauthorized
  end

  test 'should update group' do
    sign_in users(:john_doe)

    patch group_url(@group), params: { group: { name: 'Updated Group', path: 'updated_group' }, format: :turbo_stream }
    assert_redirected_to edit_group_url(@group.reload)
  end

  test 'should not update group with invalid params' do
    sign_in users(:john_doe)

    assert_no_changes -> { @group.name } do
      patch group_path(@group), params: { group: { name: 'NG' }, format: :turbo_stream }
    end
    assert_response :unprocessable_content
  end

  test 'should destroy group' do
    sign_in users(:john_doe)

    assert_difference('Group.count', -@group.self_and_descendant_ids.count) do
      delete group_url(@group)
    end

    assert_redirected_to dashboard_groups_url
  end

  test 'should not destroy group if user does not have sufficient permissions' do
    sign_in users(:joan_doe)

    assert_no_difference('Group.count') do
      delete group_path(@group)
    end

    assert_response :unauthorized
  end

  test 'should transfer group' do
    sign_in users(:john_doe)
    new_namespace = groups(:group_two)

    put group_transfer_path(@group),
        params: { new_namespace_id: new_namespace.id }, as: :turbo_stream

    assert_response :redirect
  end

  test 'should not create a new transfer with wrong parameters' do
    sign_in users(:john_doe)

    put group_transfer_path(@group),
        params: { new_namespace_id: 'asdfasd' }, as: :turbo_stream

    assert_response :unprocessable_content
  end

  test 'should not transfer a group without permission' do
    sign_in users(:joan_doe)
    new_namespace = groups(:group_two)

    put group_transfer_path(@group),
        params: { new_namespace_id: new_namespace.id }, as: :turbo_stream

    assert_response :unauthorized
  end
end
