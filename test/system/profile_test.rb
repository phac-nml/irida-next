# frozen_string_literal: true

require 'application_system_test_case'

class ProfileTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
  end

  test 'is accessible' do
    visit profile_path

    assert_accessible
  end

  test 'can update profile email' do
    visit profile_path

    within %(form[action="/-/profile"]) do
      assert_selector %(input[id="user_email"]) do |input|
        assert_equal users(:john_doe).email, input['value']
      end

      fill_in 'Email', with: 'fred_doe@gmail.com'
      click_button I18n.t(:'profiles.show.email.submit')
    end

    assert_text I18n.t(:'profiles.update.success')
  end

  test 'can update profile password' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.password')

    within %(form[action="/-/profile/password"]) do
      fill_in 'Current password', with: 'password1'
      fill_in 'Password', with: 'new_password'
      fill_in 'Password confirmation', with: 'new_password'
      click_button I18n.t(:'profiles.passwords.update.submit')
    end

    assert_text I18n.t(:'profiles.passwords.update.success')
  end

  test 'can delete profile' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.account')

    accept_alert do
      click_link I18n.t(:'profiles.accounts.delete.button')
    end

    assert_text 'Register now'
  end
end
