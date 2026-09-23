# frozen_string_literal: true

require 'test_helper'

class ProfilesIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get show' do
    get profile_url

    assert_response :success
  end

  test 'should update profile password' do
    assert_changes -> { @user.reload.valid_password?('new_password') } do
      patch profile_password_path,
            params: { user: { password: 'new_password', password_confirmation: 'new_password',
                              current_password: 'password1' } }
    end

    assert_response :redirect
    assert_equal I18n.t(:'profiles.passwords.update.success'), flash[:success]
  end

  test 'should update a users email' do
    assert_changes -> { @user.reload.email }, from: 'john.doe@localhost', to: 'your.email@gmail.com' do
      patch profile_url, params: { user: { email: 'your.email@gmail.com' } }
    end

    assert_response :redirect
    assert_equal I18n.t(:'profiles.update.success'), flash[:success]
  end

  test 'should update user fields' do
    assert_changes -> { @user.reload.email }, from: 'john.doe@localhost', to: 'johnny.deer@localhost' do
      assert_changes -> { @user.reload.first_name }, from: 'John', to: 'johnny' do
        assert_changes -> { @user.reload.last_name }, from: 'Doe', to: 'deer' do
          patch profile_url, params: { user:
          {
            email: 'johnny.deer@localhost',
            first_name: 'johnny',
            last_name: 'deer'
          } }
        end
      end
    end

    assert_response :redirect
    assert_equal I18n.t(:'profiles.update.success'), flash[:success]
  end

  test 'should not update a users email with a blank email' do
    assert_no_changes -> { @user.reload.email } do
      patch profile_url, params: { user: { email: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'should not update a users first_name with a blank first_name' do
    assert_no_changes -> { @user.reload.first_name } do
      patch profile_url, params: { user: { first_name: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'should not update a users last_name with a blank last_name' do
    assert_no_changes -> { @user.reload.last_name } do
      patch profile_url, params: { user: { last_name: '' } }
    end

    assert_response :unprocessable_content
  end
end
