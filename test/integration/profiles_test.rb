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
    assert_nil @user.provider
    assert_profile_form
  end

  test 'should show domain user details' do
    user = users(:jeff_doe)
    sign_in user

    get profile_url

    assert_response :success
    assert_not_nil user.provider
    assert_select 'dl' do
      assert_select 'dd', text: user.provider, count: 1
    end
    assert_select "form[action='#{profile_path}']", count: 0
  end

  test 'should show missing values for blank domain user fields' do
    User.any_instance.stubs(:email).returns('')
    User.any_instance.stubs(:provider).returns('')
    User.any_instance.stubs(:uid).returns('')
    User.any_instance.stubs(:first_name).returns('')
    User.any_instance.stubs(:last_name).returns('')
    sign_in users(:jeff_doe)

    get profile_url

    assert_response :success
    assert_select 'dd', text: I18n.t('profiles.show.missing'), count: 5
  end

  test 'should update profile password' do
    assert_changes -> { @user.reload.valid_password?('new_password') } do
      patch profile_password_path,
            params: { user: { password: 'new_password', password_confirmation: 'new_password',
                              current_password: 'password1' } }
    end

    assert_response :redirect
    assert_redirected_to edit_profile_password_path
    follow_redirect!
    assert_select 'h1', text: I18n.t(:'profiles.passwords.update.title'), count: 1
    assert_select "form[action='#{profile_password_path}'][method='post']" do
      assert_select "input[name='_method'][value='patch']", count: 1
      assert_select 'input#user_current_password[type="password"]', count: 1
      assert_select 'input#user_password[type="password"]', count: 1
      assert_select 'input#user_password_confirmation[type="password"]', count: 1
    end
    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div', "#{I18n.t('common.statuses.success')}: #{I18n.t(:'profiles.passwords.update.success')}"
    end
  end

  test 'should update a users email' do
    assert_changes -> { @user.reload.email }, from: 'john.doe@localhost', to: 'your.email@gmail.com' do
      patch profile_url, params: { user: { email: 'your.email@gmail.com' } }
    end

    assert_response :redirect
    follow_redirect!
    assert_profile_form
    assert_select 'input#user_email[value="your.email@gmail.com"]', count: 1
    assert_profile_update_success_flash
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
    follow_redirect!
    assert_profile_form
    assert_select 'input#user_email[value="johnny.deer@localhost"]', count: 1
    assert_select 'input#user_first_name[value="johnny"]', count: 1
    assert_select 'input#user_last_name[value="deer"]', count: 1
    assert_profile_update_success_flash
  end

  test 'should not update a user field with a blank value' do
    blank_cases = [
      { field: :email, error_selector: '#user_email_error li' },
      { field: :first_name, error_selector: '#user_first_name_error li' },
      { field: :last_name, error_selector: '#user_last_name_error li' }
    ]

    blank_cases.each do |blank_case|
      field = blank_case.fetch(:field)

      assert_no_changes -> { @user.reload.public_send(field) } do
        patch profile_url, params: { user: { field => '' } }
      end

      assert_response :unprocessable_content
      assert_profile_form
      assert_select blank_case.fetch(:error_selector), minimum: 1
    end
  end

  private

  def assert_profile_form
    assert_select 'h1', text: I18n.t(:'profiles.show.title'), count: 1
    assert_select "form[action='#{profile_path}'][method='post']" do
      assert_select "input[name='_method'][value='patch']", count: 1
      assert_select 'input#user_email[type="email"]', count: 1
      assert_select 'input#user_first_name[type="text"]', count: 1
      assert_select 'input#user_last_name[type="text"]', count: 1
    end
  end

  def assert_profile_update_success_flash
    assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
      assert_select 'div', "#{I18n.t('common.statuses.success')}: #{I18n.t(:'profiles.update.success')}"
    end
  end
end
