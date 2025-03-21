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

      w3c_validate 'Group Members Listing Page'
    end

    test 'should display add new member to group page' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get new_group_member_path(group, format: :turbo_stream)
      assert_response :success
    end

    test 'should add new member to group' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      user = users(:steve_doe)

      assert_difference('Member.count') do
        post group_members_path, params: { member: { user_id: user.id,
                                                     access_level: Member::AccessLevel::OWNER }, format: :turbo_stream }
      end

      assert_response :success
    end

    test 'should delete a member from the group' do
      sign_in users(:john_doe)

      group = groups(:group_one)
      get group_members_path(group)
      group_member = members(:group_one_member_james_doe)

      assert_difference('Member.count', -1) do
        delete group_member_path(group, group_member, format: :turbo_stream)
      end

      assert_response :ok
    end

    test 'shouldn\'t delete a member from the group' do
      sign_in users(:joan_doe)

      group = groups(:group_one)
      group_member = members(:group_one_member_james_doe)

      assert_no_difference('Member.count') do
        delete group_member_path(group, group_member, format: :turbo_stream)
      end

      assert_response :unprocessable_entity
    end
  end
end
