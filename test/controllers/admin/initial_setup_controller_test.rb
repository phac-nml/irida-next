# frozen_string_literal: true

require 'test_helper'

module Admin
  class CheckInitialSetupControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:john_doe)
      sign_in @user
    end

    test 'update only user to an admin if in initial setup state' do
      users = User.all - [@user]
      users.each(&:destroy)

      get admin_initial_setup_url(id: @user.id, initial_setup: true)

      assert @user.reload.admin?

      # redirect to sign in page after initial account setup
      assert_response :redirect, to: new_user_session_path
    end

    test 'if an account already exists a new one should not be setup as an admin' do
      user = User.last

      get admin_initial_setup_url(id: user.id, initial_setup: true)

      assert_not @user.reload.admin?

      # redirect to dashboard
      assert_response :redirect, to: root_path
    end

    test 'No initial setup completed' do
      users = User.all
      users.each(&:destroy)

      get admin_initial_setup_url(id: '123', initial_setup: true)

      # redirect to new user registration
      assert_response :redirect, to: new_user_registration_path
    end
  end
end
