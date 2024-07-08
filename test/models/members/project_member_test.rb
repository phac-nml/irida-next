# frozen_string_literal: true

require 'test_helper'

class ProjectMemberTest < ActiveSupport::TestCase
  def setup
    @project_member = members(:project_two_member_james_doe)
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

    @project_member.access_level = valid_access_levels.last + 100
    assert_not @project_member.valid?
  end

  test '#validates access level nil' do
    @project_member.access_level = nil
    assert_not @project_member.valid?
  end

  test '#validates uniquess of user in group namespace' do
    @project_member.user_id = ActiveRecord::FixtureSet.identify(:joan_doe, :uuid)
    assert_not @project_member.valid?
  end

  test 'should return correct access levels for access level MAINTAINER' do
    project_member = members(:project_two_member_joan_doe)
    assert_equal project_member.access_level, Member::AccessLevel::MAINTAINER
    access_levels = Member::AccessLevel.access_level_options_for_user(project_member.namespace, project_member.user)
    assert_not access_levels.key?(I18n.t('activerecord.models.member.access_level.owner'))
  end

  test 'should return correct access levels for access level OWNER' do
    assert_equal @project_member.access_level, Member::AccessLevel::OWNER
    access_levels = Member::AccessLevel.access_level_options_for_user(@project_member.namespace, @project_member.user)
    assert access_levels.key?(I18n.t('activerecord.models.member.access_level.owner'))
  end

  test 'should return no access levels for access level other than OWNER or MAINTAINER' do
    project_member = members(:project_two_member_ryan_doe)
    assert_equal project_member.access_level, Member::AccessLevel::GUEST
    access_levels = Member::AccessLevel.access_level_options_for_user(project_member.namespace, project_member.user)
    assert access_levels.empty?
  end

  test '#validates namespace' do
    # members namesapce is set to group
    assert @project_member.valid?

    # members namespace set to user namespace
    @project_member.namespace = namespaces_user_namespaces(:john_doe_namespace)
    assert_not @project_member.valid?
  end

  test 'access level as human readable string' do
    # access level = 40
    assert_equal @project_member.access_level, Member::AccessLevel::OWNER
    assert_equal Member::AccessLevel.human_access(@project_member.access_level),
                 I18n.t('activerecord.models.member.access_level.owner')

    project_member = members(:project_two_member_joan_doe)
    assert_equal Member::AccessLevel.human_access(project_member.access_level),
                 I18n.t('activerecord.models.member.access_level.maintainer')
  end

  test '#validate higher access than group' do
    proj_member = members(:project_two_member_james_doe_wo_john_doe_namespace)
    proj_member.access_level = Member::AccessLevel::GUEST
    assert_not proj_member.valid?
  end

  test '#path' do
    assert_equal @project.path, @project.namespace.path
  end

  test '#human_name' do
    assert_equal @project.human_name, @project.namespace.human_name
  end

  test '#full_path' do
    assert_equal @project.full_path, @project.namespace.full_path
  end

  test '#destroy removes member, then is restored' do
    assert_difference(-> { Member.count } => -1) do
      @project_member.destroy
    end

    assert_difference(-> { Member.count } => +1) do
      Member.restore(@project_member.id, recursive: true)
    end
  end

  test '#scope for_namespace_and_ancestors returns the correct collection' do
    project = projects(:project1)

    members = Member.for_namespace_and_ancestors(project)

    group_and_ancestors = project.namespace.parent&.self_and_ancestors

    memberships = group_and_ancestors.map(&:group_members)

    memberships = memberships.flatten

    assert memberships.count == members.count
    assert_same_unique_elements(members, memberships)
  end

  test '#scope not_expired for_namespace_and_ancestors returns the correct collection' do
    members = Member.for_namespace_and_ancestors(@project.namespace).not_expired
    assert_difference(-> { members.count } => -1) do
      @project_member.expires_at = 10.days.ago.to_date
      @project_member.save
    end
  end
end
