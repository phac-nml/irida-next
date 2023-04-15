# frozen_string_literal: true

require 'test_helper'

module Groups
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'create group with valid params' do
      valid_params = { name: 'group1', path: 'group1', parent_id: nil }

      assert_difference -> { Group.count } => 1, -> { Members::GroupMember.count } => 1 do
        Groups::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create group with invalid params' do
      invalid_params = { name: 'gr', path: 'gr' }

      assert_no_difference ['Group.count', 'Members::GroupMember.count'] do
        Groups::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create group with valid params but no namespace permissions' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:group_one).id }
      user = users(:michelle_doe)

      assert_no_difference ['Group.count', 'Members::GroupMember.count'] do
        Groups::CreateService.new(user, valid_params).execute
      end
    end

    test 'create subgroup within a parent group that the user is a part of with OWNER role' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:subgroup_one_group_three).id }
      user = users(:michelle_doe)

      # The user is already a member of a parent group so they are not added as a direct member to this group
      assert_difference -> { Group.count } => 1, -> { Members::GroupMember.count } => 0 do
        Groups::CreateService.new(user, valid_params).execute
      end
    end

    test 'create subgroup within a parent group that the user is a part of with not OWNER role' do
      valid_params = { name: 'group1', path: 'group1', parent_id: groups(:subgroup_one_group_three).id }
      user = users(:micha_doe)

      assert_no_difference ['Group.count', 'Members::GroupMember.count'] do
        Groups::CreateService.new(user, valid_params).execute
      end
    end
  end
end
