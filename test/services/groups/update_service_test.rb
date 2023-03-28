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

      assert_changes -> { [@group.name, @group.path] } do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end
    end

    test 'update group with invalid params' do
      invalid_params = { name: 'g1', path: 'g1' }

      assert_no_changes -> { @group } do
        Groups::UpdateService.new(@group, @user, invalid_params).execute
      end
    end
  end
end
