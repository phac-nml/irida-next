# frozen_string_literal: true

require 'application_system_test_case'

class SessionsTest < ApplicationSystemTestCase
  test 'should redirect during sign in with local account' do
    visit new_user_session_path

    assert_selector 'h1', text: I18n.t(:'devise.layout.title'), count: 1

    within %(div[class="grid gap-2"]) do
      click_link I18n.t(:'devise.sessions.new_with_providers.local_button')
    end

    assert_text I18n.t(:'devise.sessions.new_with_providers.return_button')
    assert_current_path '/users/sign_in?local=true'
  end
end
