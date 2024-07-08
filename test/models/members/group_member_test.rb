# frozen_string_literal: true

require 'test_helper'

class GroupMemberTest < ActiveSupport::TestCase
  def setup
    @group_member = members(:group_one_member_james_doe)
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

    @group_member.access_level = valid_access_levels.last + 100
    assert_not @group_member.valid?
  end

  test '#validates access level nil' do
    @group_member.access_level = nil
    assert_not @group_member.valid?
  end

  test '#validates uniquess of user in group namespace' do
    @group_member.user_id = ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    assert_not @group_member.valid?
  end

  test 'should return correct access levels for access level MAINTAINER' do
    group_member = members(:group_one_member_joan_doe)
    assert_equal group_member.access_level, Member::AccessLevel::MAINTAINER
    access_levels = Member::AccessLevel.access_level_options_for_user(group_member.namespace, group_member.user)
    assert_not access_levels.key?(I18n.t('activerecord.models.member.access_level.owner'))
  end

  test 'should return correct access levels for access level OWNER' do
    assert_equal @group_member.access_level, Member::AccessLevel::OWNER
    access_levels = Member::AccessLevel.access_level_options_for_user(@group_member.namespace, @group_member.user)
    assert access_levels.key?(I18n.t('activerecord.models.member.access_level.owner'))
  end

  test 'should return no access levels for access level other than OWNER or MAINTAINER' do
    group_member = members(:group_one_member_ryan_doe)
    assert_equal group_member.access_level, Member::AccessLevel::GUEST
    access_levels = Member::AccessLevel.access_level_options_for_user(group_member.namespace, group_member.user)
    assert access_levels.empty?
  end

  test '#validates namespace' do
    # members namesapce is set to group
    assert @group_member.valid?

    # members namespace set to user namespace
    @group_member.namespace = namespaces_user_namespaces(:john_doe_namespace)
    assert_not @group_member.valid?
  end

  test 'access level as human readable string' do
    # access level = 40
    assert_equal @group_member.access_level, Member::AccessLevel::OWNER
    assert_equal Member::AccessLevel.human_access(@group_member.access_level),
                 I18n.t('activerecord.models.member.access_level.owner')

    group_member = members(:group_one_member_joan_doe)
    assert_equal Member::AccessLevel.human_access(group_member.access_level),
                 I18n.t('activerecord.models.member.access_level.maintainer')
  end

  test '#validates that the last remaining owner of a group is not deleted' do
    group = groups(:group_two)

    group_member = members(:group_two_member_john_doe)

    group_member.destroy

    assert group_member.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.member.destroy.last_member',
             namespace_type: group.class.model_name.human)
    )
  end

  test '#destroy removes member' do
    assert_difference(-> { Member.count } => -1) do
      @group_member.destroy
    end
  end

  test '#destroy removes member, then is restored' do
    assert_difference(-> { Member.count } => -1) do
      @group_member.destroy
    end

    assert_difference(-> { Member.count } => +1) do
      Member.restore(@group_member.id, recursive: true)
    end
  end

  test '#scope for_namespace_and_ancestors returns the correct collection' do
    namespace = groups(:subgroup1)
    members = Member.for_namespace_and_ancestors(namespace)

    group_and_ancestors = namespace.self_and_ancestors
    memberships = group_and_ancestors.map(&:group_members)

    memberships = memberships.flatten

    assert memberships.count == members.count
    assert_same_unique_elements(members, memberships)
  end

  test '#scope not_expired for_namespace_and_ancestors returns the correct collection' do
    members = Member.for_namespace_and_ancestors(@group).not_expired
    assert_difference(-> { members.count } => -1) do
      @group_member.expires_at = 10.days.ago.to_date
      @group_member.save
    end
  end
end
