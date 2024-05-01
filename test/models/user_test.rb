# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
  end

  test 'valid user' do
    assert @user.valid?
  end

  test 'invalid without email' do
    @user.email = nil
    assert_not @user.valid?
    assert_not_nil @user.errors[:email]
  end

  test 'should update namespace when email changes' do
    @user.email = 'john.doe@example'
    namespace_path_before = @user.namespace.path
    namespace_name_before = @user.namespace.name
    assert @user.save
    assert_not_equal namespace_path_before, @user.namespace.path
    assert_not_equal namespace_name_before, @user.namespace.name
  end

  test '#personal_access_tokens' do
    assert_equal 5, @user.personal_access_tokens.size
  end

  test '#destroy removes dependant user namespace, and projects' do
    projects_count = @user.namespace.project_namespaces.count
    assert_difference(
      -> { User.count } => -1,
      -> { Namespaces::ProjectNamespace.count } => (projects_count * -1),
      -> { Project.count } => (projects_count * -1)
    ) do
      @user.destroy
    end
  end

  test 'username' do
    assert_equal 'john.doe', @user.username
  end

  test 'to_param' do
    assert_equal 'john.doe_at_localhost', @user.to_param
  end

  test 'ensure_namespace with valid user with namespace' do
    assert_equal 'john.doe@localhost', @user.send(:ensure_namespace)
  end

  test 'ensure_namespace with bot' do
    bot_user = users(:project1_automation_bot)
    assert_nil bot_user.namespace
    assert_no_changes -> { bot_user.namespace } do
      bot_user.save
    end
  end

  test 'ensure_namespace with new user with no namespace' do
    user = User.new(email: 'new_user@email.com')
    assert_nil user.namespace
    user.save

    assert_equal 'new_user_at_email.com', user.namespace.path
    assert_equal 'new_user@email.com', user.namespace.name
  end

  test 'skipping password_required?' do
    new_user = User.new
    new_user.skip_password_validation = true

    password_required = new_user.send(:password_required?)

    assert_not password_required
  end

  test 'update password' do
    params = { password: 'new_password', password_confirmation: 'new_password',
               current_password: 'password1' }

    assert @user.update_password_with_password(params)
  end

  test 'unable to update password with wrong password_confirmation' do
    params = { password: 'new_password', password_confirmation: 'invalid_confirmation',
               current_password: 'password1' }

    assert_not @user.update_password_with_password(params)
    assert_equal "Password confirmation doesn't match Password", @user.errors.full_messages.first
  end

  test 'unable to update password with blank password' do
    params = { password: ' ', password_confirmation: ' ',
               current_password: 'password1' }

    assert_not @user.update_password_with_password(params)
    assert_equal "Password can't be blank", @user.errors.full_messages.first
  end

  test 'unable to update password with wrong password' do
    params = { password: 'new_password', password_confirmation: 'new_password',
               current_password: 'wrong_password' }

    assert_not @user.update_password_with_password(params)
    assert_equal 'Current password is invalid', @user.errors.full_messages.first
  end
end
