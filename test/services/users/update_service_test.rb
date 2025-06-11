# frozen_string_literal: true

require 'test_helper'

module Users
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'update user params' do
      params = { email: 'newemail@email.com', first_name: 'new_first_name', last_name: 'new_last_name' }

      assert_changes lambda {
        [@user.email, @user.first_name, @user.last_name]
      }, to: %w[newemail@email.com new_first_name new_last_name] do
        Users::UpdateService.new(@user, @user, params).execute
      end
    end

    test 'update user to admin during initial setup' do
      users = User.all - [@user]
      users.each(&:destroy)

      assert_not @user.admin?

      params = { admin: true, initial_setup: true }

      assert_changes lambda {
        @user.admin
      }, to: true do
        Users::UpdateService.new(nil, @user, params).execute
      end
    end

    test 'admin can update users' do
      user = User.last
      params = { email: 'newemail@email.com', first_name: 'new_first_name', last_name: 'new_last_name' }

      assert_changes lambda {
        [user.email, user.first_name, user.last_name]
      }, to: %w[newemail@email.com new_first_name new_last_name] do
        Users::UpdateService.new(@user, user, params).execute
      end
    end
  end
end
