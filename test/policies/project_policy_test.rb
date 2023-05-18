# frozen_string_literal: true

require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @project = projects(:project1)
    @policy = ProjectPolicy.new(@project, user: @user)
    @details = {}
  end

  test '#view?' do
    assert @policy.view?
  end

  test '#manage?' do
    assert @policy.manage?
  end

  test '#destroy?' do
    assert @policy.destroy?
  end

  test '#transfer?' do
    assert @policy.transfer?
  end

  test 'aliases' do
    assert_equal :manage?, @policy.resolve_rule(:create?)
    assert_equal :manage?, @policy.resolve_rule(:edit?)
    assert_equal :manage?, @policy.resolve_rule(:update?)
    assert_equal :manage?, @policy.resolve_rule(:new?)

    assert_equal :view?, @policy.resolve_rule(:index?)
    assert_equal :view?, @policy.resolve_rule(:show?)
    assert_equal :view?, @policy.resolve_rule(:activity?)

    assert_equal :destroy?, @policy.resolve_rule(:destroy?)

    assert_equal :transfer?, @policy.resolve_rule(:transfer?)
  end

  test 'scope' do
    scoped_projects = @policy.apply_scope(Project, type: :relation)
    # John Doe has access to 23 projects
    assert_equal scoped_projects.count, 25

    user = users(:david_doe)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation)
    # David Doe has access to 0 projects
    assert_equal scoped_projects.count, 0
  end
end
