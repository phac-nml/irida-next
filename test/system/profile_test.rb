# frozen_string_literal: true

require 'application_system_test_case'

class ProfileTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    login_as @user
    @active_token_count = @user.personal_access_tokens.active.count
  end

  test 'is accessible' do
    visit profile_path

    assert_accessible
  end

  test 'can update profile email' do
    visit profile_path

    within %(form[action="/-/profile"]) do
      assert_equal @user.email, find_field(I18n.t('activerecord.attributes.user.email')).value

      fill_in I18n.t('activerecord.attributes.user.email'), with: 'fred_doe@gmail.com'
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

    click_link I18n.t(:'profiles.accounts.delete.button')

    within('#turbo-confirm[open]') do
      click_on I18n.t(:'components.confirmation.confirm')
    end

    assert_selector 'h1', text: I18n.t(:'devise.layout.title')
  end

  test 'can view personal access tokens' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.access_tokens')

    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count)
  end

  test 'can create personal access tokens' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.access_tokens')

    within %(form[action="/-/profile/personal_access_tokens"]) do
      fill_in 'Token name', with: 'my new token'
      check 'api', allow_label_click: true
      click_button I18n.t(:'profiles.personal_access_tokens.create.submit')
    end

    assert_text I18n.t(:'profiles.personal_access_tokens.access_token_section.label')
    assert_text I18n.t(:'profiles.personal_access_tokens.access_token_section.description')

    assert_text 'my new token'
    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count + 1)
  end

  test 'can revoke personal access tokens' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.access_tokens')

    token_to_revoke = @user.personal_access_tokens.active.first

    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count)
    assert_text token_to_revoke.name

    within %(tr[id=personal_access_token_#{token_to_revoke.id}]) do
      click_button I18n.t(:'profiles.personal_access_tokens.personal_access_token.revoke_button')
    end

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_no_text token_to_revoke.name
    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count - 1)
  end

  test 'can view language selection' do
    visit profile_preferences_path

    assert_text I18n.t(:'profiles.preferences.locale_form.en')
  end

  test 'can update language to french' do
    visit profile_preferences_path

    find('input[id=user_locale_fr]').click

    I18n.with_locale(:fr) do
      assert_text I18n.t(:'profiles.preferences.locale_form.en')
      within %(div[data-controller='viral--flash']) do
        assert_text I18n.t(:'profiles.preferences.update.success')
      end
    end
  end
end
