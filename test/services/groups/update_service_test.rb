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

      assert_changes -> { [@group.name, @group.path] }, to: %w[new-group1-name new-group1-path] do
        Groups::UpdateService.new(@group, @user, valid_params).execute
      end
    end

    test 'update group with invalid params' do
      invalid_params = { name: 'g1', path: 'g1' }

      assert_no_changes -> { @group } do
        Groups::UpdateService.new(@group, @user, invalid_params).execute
      end
    end

    test 'update group with incorrect permissions' do
      valid_params = { name: 'new-group1-name', path: 'new-group1-path' }
      user = users(:joan_doe)

      assert_no_changes -> { @group } do
        Groups::UpdateService.new(@group, user, valid_params).execute
      end
      assert @group.errors.full_messages.include?(I18n.t('services.groups.update.no_permission'))
    end
  end
end
