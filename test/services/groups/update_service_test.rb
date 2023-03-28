# frozen_string_literal: true

require 'test_helper'

module Groups
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_one)
    end

    test 'update group with valid params' do
      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }

      Groups::UpdateService.new(@group, @user, valid_params).execute

      assert_equal 'new-group1-name', @group.reload.name
      assert_equal 'new-group1-path', @group.reload.path
    end

    test 'update group with invalid params' do
      invalid_params = { name: 'g1', path: 'g1' }

      Groups::UpdateService.new(@group, @user, invalid_params).execute

      assert_not_equal 'g1', @group.reload.name
      assert_not_equal 'g1', @group.reload.path
    end
  end
end
