# frozen_string_literal: true

require 'test_helper'

module Groups
  class MembersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get group members listing => members#index' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      assert_response :success
    end

    test 'should display add new member to group page' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get new_group_member_path(group)
      assert_response :success
    end

    test 'should add new member to group' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      user = users(:john_doe)

      assert_difference('Members::GroupMember.count') do
        post group_members_path, params: { member: { user_id: user.id,
                                                     namespace_id: group.id,
                                                     created_by_id: user.id,
                                                     type: 'GroupMember',
                                                     access_level: Member::AccessLevel::OWNER } }
      end

      assert_redirected_to group_members_path(group)
    end

    test 'should delete a member from the group' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      group_member = members_group_members(:group_one_member_james_doe)

      assert_difference('Members::GroupMember.count', -1) do
        delete group_member_path(group, group_member)
      end

      assert_redirected_to group_members_path(group)
    end
  end
end