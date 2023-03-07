# frozen_string_literal: true

require 'test_helper'

class GroupMemberTest < ActiveSupport::TestCase
  def setup
    @group_member = group_members(:group_one_member_james_doe)
    @group = groups(:group_one)
    @created_by_user = users(:john_doe)
    @user = users(:james_doe)
  end

  test 'valid group member' do
    assert @group_member.valid?
  end

  test '#group' do
    assert_equal @group, @group_member.group
  end

  test '#created by' do
    assert_equal @created_by_user, @group_member.created_by
  end

  test '#user' do
    assert_equal @user, @group_member.user
  end

  test '#role' do
    assert_equal 'Owner', @group_member.role
  end

  test '#type' do
    assert_equal 'GroupMember', @group_member.type
  end
end
