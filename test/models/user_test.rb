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
end
