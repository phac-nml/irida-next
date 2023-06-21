# frozen_string_literal: true

require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @project = projects(:project1)
    @policy = ProjectPolicy.new(@project, user: @user)
    @details = {}
  end

  test '#read?' do
    assert @policy.read?
  end

  test '#edit?' do
    assert @policy.edit?
  end

  test '#new?' do
    assert @policy.new?
  end

  test '#update?' do
    assert @policy.update?
  end

  test '#activity?' do
    assert @policy.activity?
  end

  test '#destroy?' do
    assert @policy.destroy?
  end

  test '#transfer?' do
    assert @policy.transfer?
  end

  test '#sample_listing?' do
    assert @policy.sample_listing?
  end

  test '#create_sample?' do
    assert @policy.create_sample?
  end

  test '#update_sample?' do
    assert @policy.update_sample?
  end

  test '#transfer_sample?' do
    assert @policy.transfer_sample?
  end

  test '#destroy_sample?' do
    assert @policy.destroy_sample?
  end

  test '#read_sample?' do
    assert @policy.destroy_sample?
  end

  test '#transfer_sample_into_project?' do
    assert @policy.transfer_sample_into_project?
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

  test 'receivable scope' do
    scoped_projects = @policy.apply_scope(Project, type: :relation, name: :receivable)

    assert_equal 8, scoped_projects.count
  end
end
