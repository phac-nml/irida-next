# frozen_string_literal: true

require 'test_helper'

class PreferencesTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get show' do
    get profile_preferences_path

    assert_response :success
    assert_select 'input#user_locale_en', count: 1
    assert_select 'input#user_locale_fr', count: 1
  end

  test 'should update the users locale with a valid locale via html' do
    assert_changes -> { @user.reload.locale }, from: 'en', to: 'fr' do
      patch profile_preferences_path,
            params: { user: { locale: 'fr' } }
    end

    assert_redirected_to profile_preferences_path
    assert_equal I18n.t(:'profiles.preferences.update.success', locale: :fr), flash[:success]
  end

  test 'should update the users locale with a valid locale' do
    assert_changes -> { @user.reload.locale }, from: 'en', to: 'fr' do
      patch profile_preferences_path,
            params: { user: { locale: 'fr' } }
    end

    assert_redirected_to profile_preferences_path
    assert_equal I18n.t(:'profiles.preferences.update.success', locale: :fr), flash[:success]
  end

  test 'should update the users locale with a valid locale via turbo stream' do
    assert_changes -> { @user.reload.locale }, from: 'en', to: 'fr' do
      patch profile_preferences_path(format: :turbo_stream),
            params: { user: { locale: 'fr' } }
    end

    assert_response :ok
    assert_includes response.body, I18n.t(:'profiles.preferences.update.success', locale: :fr)
  end

  test 'should not update the users locale with an invalid locale via turbo stream' do
    assert_no_changes -> { @user.reload.locale } do
      patch profile_preferences_path(format: :turbo_stream),
            params: { user: { locale: 'not_a_locale' } }
    end

    assert_response :unprocessable_content
    assert_includes response.body, I18n.t(:'profiles.preferences.update.error')
  end

  test 'should render the preferences page with an error when the update fails' do
    update_service = mock('update_service')
    update_service.expects(:execute).returns(false)
    Users::UpdateService.stubs(:new).returns(update_service)

    assert_no_changes -> { @user.reload.locale } do
      patch profile_preferences_path,
            params: { user: { locale: 'en' } }
    end

    assert_response :unprocessable_content
    assert_equal I18n.t(:'profiles.preferences.update.error'), flash[:error]
  end

  test 'should redirect unauthenticated users on update' do
    delete destroy_user_session_path

    assert_no_changes -> { @user.reload.locale } do
      patch profile_preferences_path,
            params: { user: { locale: 'fr' } }
    end

    assert_response :redirect
  end
end
