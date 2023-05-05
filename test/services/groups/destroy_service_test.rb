# frozen_string_literal: true

require 'test_helper'

module Groups
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_one)
    end

    test 'delete group with correct permissions' do
      assert_difference -> { Group.count } => -1 do
        Groups::DestroyService.new(@group, @user).execute
      end
      assert @group.errors.empty?
    end

    test 'delete group with incorrect permissions' do
      user = users(:joan_doe)

      assert_raises(ActionPolicy::Unauthorized) { Groups::DestroyService.new(@group, user).execute }
    end
  end
end
