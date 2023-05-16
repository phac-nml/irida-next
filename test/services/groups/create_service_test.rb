# frozen_string_literal: true

require 'test_helper'

module Groups
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'create group with valid params' do
      valid_params = { name: 'group1', path: 'group1', parent_id: nil }

      assert_difference -> { Group.count } => 1, -> { Member.count } => 1 do
        Groups::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create group with invalid params' do
      invalid_params = { name: 'gr', path: 'gr' }

      assert_no_difference ['Group.count', 'Member.count'] do
        Groups::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create group with valid params but no namespace permissions' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:group_one).id }
      user = users(:michelle_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::CreateService.new(user, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :allowed_to_modify_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'create subgroup within a parent group that the user is a part of with OWNER role' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:subgroup_one_group_three).id }
      user = users(:michelle_doe)

      # The user is already a member of a parent group so they are not added as a direct member to this group
      assert_difference -> { Group.count } => 1, -> { Member.count } => 0 do
        Groups::CreateService.new(user, valid_params).execute
      end
    end

    test 'create subgroup within a parent group that the user is a part of with MAINTAINER role' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:subgroup_one_group_three).id }
      user = users(:micha_doe)

      assert_difference -> { Group.count } => 1, -> { Member.count } => 0 do
        Groups::CreateService.new(user, valid_params).execute
      end
    end

    test 'create subgroup within a parent group that the user is a part of with role < MAINTAINER' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:subgroup_one_group_three).id }
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::CreateService.new(user, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :allowed_to_modify_group?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'valid authorization to create group' do
      group = groups(:group_one)
      valid_params = { name: 'group1', path: 'group1', parent_id: group.id }
      user = users(:michelle_doe)

      assert_authorized_to(:allowed_to_modify_group?, group,
                           with: GroupPolicy,
                           context: { user: }) do
        Groups::CreateService.new(user, valid_params).execute
      end
    end
  end
end
