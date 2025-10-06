# frozen_string_literal: true

require 'test_helper'

module System
  class CheckInitialSetupControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:john_doe)
      sign_in @user
    end

    test 'update only user to a system account if in initial setup state' do
      users = User.all - [@user]
      users.each(&:destroy)

      get system_initial_setup_url(id: @user.id)

      assert @user.reload.system?

      # redirect to sign in page after initial account setup
      assert_response :redirect, to: new_user_session_path
    end

    test 'if an account already exists a new one should not be setup as a system account' do
      user = User.last

      get system_initial_setup_url(id: user.id)

      assert_not @user.reload.system?

      # redirect to dashboard
      assert_response :redirect, to: root_path
    end

    test 'No initial setup completed' do
      users = User.all
      users.each(&:destroy)

      get system_initial_setup_url(id: '123')

      # redirect to new user registration
      assert_response :redirect, to: new_user_registration_path
    end
  end
end
