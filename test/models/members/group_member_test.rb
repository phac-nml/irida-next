# frozen_string_literal: true

require 'test_helper'

class GroupMemberTest < ActiveSupport::TestCase
  def setup
    @group_member = members_group_members(:group_one_member_james_doe)
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

  test '#access level' do
    assert_equal Member::AccessLevel::OWNER, @group_member.access_level
  end

  test '#type' do
    assert_equal 'GroupMember', @group_member.type
  end

  test 'validates access level presence' do
    @group_member.access_level = nil
    assert_not @group_member.valid?
  end

  test '#validates access level in range' do
    valid_access_levels = Member::AccessLevel.all_values_with_owner

    @group_member.access_level = valid_access_levels.sample
    assert @group_member.valid?
  end

  test '#validates access level out of range' do
    valid_access_levels = Member::AccessLevel.all_values_with_owner

    @group_member.access_level = (valid_access_levels.sample + valid_access_levels.last)
    assert_not @group_member.valid?
  end

  test '#validates access level nil' do
    @group_member.access_level = nil
    assert_not @group_member.valid?
  end

  test '#validates uniquess of user in group namespace' do
    @group_member.user_id = ActiveRecord::FixtureSet.identify(:joan_doe)
    assert_not @group_member.valid?
  end

  test 'should return correct access levels for access level MAINTAINER' do
    group_member = members_group_members(:group_one_member_joan_doe)
    assert_equal group_member.access_level, Member::AccessLevel::MAINTAINER
    access_levels = Member.access_levels(group_member)
    assert_not access_levels.key?(I18n.t('activerecord.models.member.access_level.owner'))
  end

  test 'should return correct access levels for access level OWNER' do
    assert_equal @group_member.access_level, Member::AccessLevel::OWNER
    access_levels = Member.access_levels(@group_member)
    assert access_levels.key?(I18n.t('activerecord.models.member.access_level.owner'))
  end

  test '#validates namespace' do
    # members namesapce is set to group
    assert @group_member.valid?

    # members namespace set to user namespace
    @group_member.namespace = namespaces_user_namespaces(:john_doe_namespace)
    assert_not @group_member.valid?
  end
end
