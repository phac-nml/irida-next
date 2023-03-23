# frozen_string_literal: true

require 'test_helper'

class ProjectMemberTest < ActiveSupport::TestCase
  def setup
    @project_member = members_project_members(:project_two_member_james_doe)
    @project = projects(:john_doe_project2)
    @created_by_user = users(:john_doe)
    @user = users(:james_doe)
  end

  test 'valid project member' do
    assert @project_member.valid?
  end

  test '#project' do
    assert_equal @project, @project_member.project
  end

  test '#created by' do
    assert_equal @created_by_user, @project_member.created_by
  end

  test '#user' do
    assert_equal @user, @project_member.user
  end

  test '#access_level' do
    assert_equal Member::AccessLevel::OWNER, @project_member.access_level
  end

  test '#type' do
    assert_equal 'ProjectMember', @project_member.type
  end

  test 'validates access level presence' do
    @project_member.access_level = nil
    assert_not @project_member.valid?
  end

  test '#validates access level in range' do
    valid_access_levels = Member::AccessLevel.all_values_with_owner

    @project_member.access_level = valid_access_levels.sample
    assert @project_member.valid?
  end

  test '#validates access level out of range' do
    valid_access_levels = Member::AccessLevel.all_values_with_owner

    @project_member.access_level = valid_access_levels.sample + valid_access_levels.last
    assert_not @project_member.valid?
  end

  test '#validates access level nil' do
    @project_member.access_level = nil
    assert_not @project_member.valid?
  end

  test '#validates uniquess of user in group namespace' do
    @project_member.user_id = ActiveRecord::FixtureSet.identify(:joan_doe)
    assert_not @project_member.valid?
  end
end
