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
      fill_in 'user_current_password', with: 'password1'
      fill_in 'user_password', with: 'new_password'
      fill_in 'user_password_confirmation', with: 'new_password'
      click_button I18n.t(:'profiles.passwords.update.submit')
    end

    assert_text I18n.t(:'profiles.passwords.update.success')
  end

  test 'can delete profile' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.account')

    click_button I18n.t(:'profiles.accounts.delete.button')

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
    assert_text I18n.t('profiles.personal_access_tokens.create.success', name: 'my new token')
  end

  test 'cannot create personal access token without scope selection' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.access_tokens')

    within %(form[action="/-/profile/personal_access_tokens"]) do
      fill_in 'Token name', with: 'my new token'
      click_button I18n.t(:'profiles.personal_access_tokens.create.submit')
    end
    assert_no_text 'my new token'
    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count)
    assert_text I18n.t(:'errors.format',
                       attribute: I18n.t(:'activerecord.attributes.personal_access_token.scopes'),
                       message: I18n.t(:'errors.messages.blank'))
  end

  test 'can revoke personal access tokens' do
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.access_tokens')

    token_to_revoke = personal_access_tokens(:john_doe_non_expirable_pat)

    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count)
    within('#access-tokens-table') do
      assert_text token_to_revoke.name
    end
    within %(tr[id="#{dom_id(token_to_revoke)}"]) do
      click_button I18n.t(:'personal_access_tokens.table.revoke')
    end

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end
    within('#access-tokens-table') do
      assert_no_text token_to_revoke.name
    end
    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: @active_token_count - 1)
  end

  test 'empty personal access tokens state' do
    login_as users(:empty_doe)
    visit profile_path
    click_link I18n.t(:'profiles.sidebar.access_tokens')

    assert_text I18n.t(:'profiles.personal_access_tokens.index.active_personal_access_tokens',
                       count: 0)
    assert_no_selector 'table#personal-access-tokens-table'

    assert_text I18n.t('profiles.personal_access_tokens.table.empty_state.title')
    assert_text I18n.t('profiles.personal_access_tokens.table.empty_state.description')
  end

  test 'can view language selection' do
    visit profile_preferences_path

    assert_text I18n.t(:'locales.en')
  end

  test 'can update language selection' do
    visit profile_preferences_path

    # change user language selection from the layout
    find('#language-selection-dd-trigger').click
    within find('#language_selection_dropdown') do
      click_button I18n.t(:'locales.fr', locale: :fr)
    end

    I18n.with_locale(:fr) do
      within %(div[data-controller='viral--flash']) do
        assert_text I18n.t(:'profiles.preferences.update.success')
      end
    end

    assert_current_path profile_preferences_path
    assert_no_selector "div[data-controller='viral--flash']"

    # change user language selection from the profile page preferences section
    find("label[for='user_locale_en']").click
    assert_selector "input[id='user_locale_en']:checked", count: 1

    I18n.with_locale(:en) do
      within %(div[data-controller='viral--flash']) do
        assert_text I18n.t(:'profiles.preferences.update.success')
      end
    end
  end
end
