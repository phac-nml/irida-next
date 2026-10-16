# frozen_string_literal: true

require 'test_helper'

class AccountsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get account show' do
    get profile_account_url

    assert_response :success
    assert_select 'h1', text: I18n.t(:'profiles.accounts.show.title'), count: 1
    assert_select 'p', text: "#{I18n.t(:'profiles.accounts.delete.description')}:", count: 1
    I18n.t(:'profiles.accounts.delete.effects').each do |effect|
      assert_select 'ul li', text: effect, count: 1
    end
    assert_select "form[action='#{profile_account_path}'][method='post']" do
      assert_select "input[name='_method'][value='delete']", count: 1
    end
    assert_select 'button', text: I18n.t(:'profiles.accounts.delete.button'), count: 1
  end

  test 'should redirect unauthenticated users from account show' do
    sign_out @user

    get profile_account_url

    assert_redirected_to new_user_session_url
  end

  test 'should delete profile' do
    assert_difference('User.count', -1) do
      delete profile_account_path
    end

    assert_redirected_to new_user_session_url
    assert_not User.exists?(@user.id)
  end

  test 'should not delete profile for unauthenticated users' do
    sign_out @user

    assert_no_difference('User.count') do
      delete profile_account_path
    end

    assert_redirected_to new_user_session_url
  end
end
