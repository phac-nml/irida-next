# frozen_string_literal: true

require 'application_system_test_case'

class SessionsTest < ApplicationSystemTestCase
  test 'should display sign in with local account' do
    visit new_user_session_path

    assert_selector 'h1', text: I18n.t(:'devise.layout.title'), count: 1

    within %(div[class="grid gap-2"]) do
      click_link I18n.t(:'devise.sessions.new_with_providers.local_button')
    end

    assert_text I18n.t(:'devise.sessions.new_with_providers.return_button')
    assert_current_path '/users/sign_in?local=true'
  end

  test 'should display error during with local account' do
    user = users(:john_doe)

    visit new_user_session_path

    assert_selector 'h1', text: I18n.t(:'devise.layout.title'), count: 1

    within %(div[class="grid gap-2"]) do
      click_link I18n.t(:'devise.sessions.new_with_providers.local_button')
    end

    within %(form[action="/users/sign_in"]) do
      fill_in 'Email', with: user.email
      click_on I18n.t('devise.shared.form.sign_in')
    end

    assert_text 'Invalid Email or password'
    within %(form[action="/users/sign_in"]) do
      assert_selector 'label', text: 'Email', count: 1
      assert_selector 'label', text: 'Password', count: 1
    end
    assert_current_path '/users/sign_in'
  end
end
