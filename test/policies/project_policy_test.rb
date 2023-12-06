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
    # John Doe has access to 30 projects. 29 through his namespace
    # and projects under groups in which he is a member plus a project
    # from David Doe's Group Four which is shared with subgroup 1 under
    # John Doe's group Group 1
    assert_equal 30, scoped_projects.count

    user = users(:david_doe)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation)

    # David Doe has access to 21 projects via a namespace
    # group link between one of his groups and group_one
    # and one project of their own under david_doe_group_four
    assert_equal 22, scoped_projects.count
  end

  test 'manageable scope' do
    scoped_projects = @policy.apply_scope(Project, type: :relation, name: :manageable)

    # John Doe has manageable access to just projects under his namespace
    # and projects under groups in which he is a member
    assert_equal 29, scoped_projects.count

    user = users(:david_doe)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation, name: :manageable)

    # David Doe has manageable access to projects under his group and
    # none through namespace group links as manageable access has not
    # been set for any of the links
    assert_equal 1, scoped_projects.count
  end
end
