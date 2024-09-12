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

  test '#clone_sample?' do
    assert @policy.clone_sample?
  end

  test '#clone_sample_into_project?' do
    assert @policy.clone_sample_into_project?
  end
  test '#export_data?' do
    assert @policy.export_data?
  end

  test '#submit_workflow?' do
    assert @policy.submit_workflow?
  end

  test '#view_attachments?' do
    assert @policy.view_attachments?
  end

  test '#create_attachment?' do
    assert @policy.create_attachment?
  end

  test '#destroy_attachment?' do
    assert @policy.destroy_attachment?
  end

  test 'scope' do
    scoped_projects = @policy.apply_scope(Project, type: :relation)
    # John Doe has access to 33 projects. 32 through his namespace
    # and projects under groups in which he is a member plus a project
    # from David Doe's Group Four which is shared with subgroup 1 under
    # John Doe's group Group 1
    assert_equal 38, scoped_projects.count

    user = users(:david_doe)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation)

    # David Doe has access to 22 projects via a namespace
    # group link between one of his groups and group_one
    # and one project of their own under david_doe_group_four
    assert_equal 22, scoped_projects.count
  end

  test 'scope expired memberships' do
    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save

    scoped_projects = @policy.apply_scope(Project, type: :relation)

    assert_equal 19, scoped_projects.count
    scoped_projects_names = Namespaces::ProjectNamespace.where(id: scoped_projects.select(:namespace_id)).pluck(:name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project5_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project6_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project7_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project8_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project9_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project10_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project11_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project12_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project13_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project14_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project15_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project16_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project17_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project18_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project19_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project20_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project21_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project24_namespace).name)

    project_member = members(:project_one_member_john_doe)
    project_member.expires_at = 10.days.ago.to_date
    project_member.save

    scoped_projects = @policy.apply_scope(Project, type: :relation)

    assert_equal 18, scoped_projects.count
    scoped_projects_names = Namespaces::ProjectNamespace.where(id: scoped_projects.select(:namespace_id)).pluck(:name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project1_namespace).name)

    linked_group_member = members(:namespace_group_link8_member1)
    linked_group_member.expires_at = 10.days.ago.to_date
    linked_group_member.save

    scoped_projects = @policy.apply_scope(Project, type: :relation)

    assert_equal 17, scoped_projects.count
    scoped_projects_names = Namespaces::ProjectNamespace.where(id: scoped_projects.select(:namespace_id)).pluck(:name)
    assert_not scoped_projects_names.include?(
      namespaces_project_namespaces(:namespace_group_link_group_one_project1_namespace).name
    )
  end

  test 'manageable scope' do
    scoped_projects = @policy.apply_scope(Project, type: :relation, name: :manageable)

    # John Doe has manageable access to just projects under his namespace
    # and projects under groups in which he is a member
    assert_equal 37, scoped_projects.count

    user = users(:david_doe)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation, name: :manageable)

    # David Doe has manageable access to projects under his group and
    # none through namespace group links as manageable access has not
    # been set for any of the links
    assert_equal 1, scoped_projects.count
  end

  test 'manageable scope expired memberships' do
    group_member = members(:group_one_member_john_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save

    scoped_projects = @policy.apply_scope(Project, type: :relation, name: :manageable)

    assert_equal 19, scoped_projects.count
    scoped_projects_names = Namespaces::ProjectNamespace.where(id: scoped_projects.select(:namespace_id)).pluck(:name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project5_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project6_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project7_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project8_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project9_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project10_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project11_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project12_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project13_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project14_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project15_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project16_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project17_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project18_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project19_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project20_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project21_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project24_namespace).name)
    assert scoped_projects_names.include?(namespaces_project_namespaces(:project25_namespace).name)

    project_member = members(:project_one_member_john_doe)
    project_member.expires_at = 10.days.ago.to_date
    project_member.save

    scoped_projects = @policy.apply_scope(Project, type: :relation, name: :manageable)

    assert_equal 18, scoped_projects.count
    scoped_projects_names = Namespaces::ProjectNamespace.where(id: scoped_projects.select(:namespace_id)).pluck(:name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:project1_namespace).name)
  end

  test 'named scope with modify access to namespace via a namespace group link ' do
    user = users(:private_joan)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation, name: :manageable)
    scoped_projects_namespaces = Namespace.where(id: scoped_projects.select(:namespace_id))
    scoped_projects_names = scoped_projects_namespaces.pluck(:name)

    assert_equal 4, scoped_projects.length
    assert_not scoped_projects_namespaces.include?(namespaces_user_namespaces(:private_joan_namespace).name)
    assert scoped_projects_names.include?(namespaces_project_namespaces(:projectDelta_namespace).name)
    assert scoped_projects_names.include?(namespaces_project_namespaces(:projectEcho_namespace).name)
    assert scoped_projects_names.include?(namespaces_project_namespaces(:projectDeltaSubgroupA_namespace).name)
    assert scoped_projects_names.include?(namespaces_project_namespaces(:projectEchoSubgroupB_namespace).name)

    direct_groups = user.groups.self_and_descendant_ids

    # Group Delta and Subgroup A
    assert_equal 2, direct_groups.length

    expected_projects = direct_groups.map { |direct_group| direct_group.project_namespaces.pluck(:name) }

    linked_namespaces = NamespaceGroupLink.where(group: direct_groups)

    assert_equal 1, linked_namespaces.length
    assert linked_namespaces.include?(namespace_group_links(:namespace_group_link15))

    linked_namespaces.each do |linked_namespace|
      expected_projects << linked_namespace.namespace.project_namespaces.pluck(:name)

      descendant_groups = linked_namespace.namespace.descendants
      descendant_groups.each do |descendant_group|
        expected_projects << descendant_group.project_namespaces.pluck(:name)
      end
    end

    expected_projects = expected_projects.flatten.sort
    actual_projects = scoped_projects_names.flatten.sort

    assert_equal expected_projects.count, actual_projects.count
    assert_equal expected_projects.flatten.sort, actual_projects.flatten.sort
  end

  test 'relation scope with direct linked projects' do
    user = users(:user27)
    policy = ProjectPolicy.new(user:)
    scoped_projects = policy.apply_scope(Project, type: :relation)
    scoped_projects_namespaces = Namespace.where(id: scoped_projects.select(:namespace_id))
    scoped_projects_names = scoped_projects_namespaces.pluck(:name)

    assert_equal 2, scoped_projects.count

    assert scoped_projects_names.include?(namespaces_project_namespaces(:user27_project1_namespace).name)
    assert scoped_projects_names.include?(namespaces_project_namespaces(:projectFoxtrotSubgroupA_namespace).name)
  end

  test 'manageable scope with direct linked projects' do
    user = users(:user27)
    policy = ProjectPolicy.new(user:)

    scoped_projects = policy.apply_scope(Project, type: :relation, name: :manageable)
    scoped_projects_namespaces = Namespace.where(id: scoped_projects.select(:namespace_id))
    scoped_projects_names = scoped_projects_namespaces.pluck(:name)

    assert_equal 1, scoped_projects.count

    assert scoped_projects_names.include?(namespaces_project_namespaces(:user27_project1_namespace).name)
    assert_not scoped_projects_names.include?(namespaces_project_namespaces(:projectFoxtrotSubgroupA_namespace).name)
  end

  test 'Correct access level through group linked to project can submit workflow' do
    # User has analyst access to project through a namespace group link

    user = users(:user30)
    project = projects(:user29_project1)

    policy = ProjectPolicy.new(project, user:)

    scoped_projects = policy.apply_scope(Project, type: :relation)

    assert_equal 1, scoped_projects.count

    assert_equal true, policy.submit_workflow?
  end

  test 'group_projects scope includes linked projects and projects from linked groups' do
    user = users(:private_ryan)
    group = groups(:group_alpha)
    policy = ProjectPolicy.new(group, user:)

    scoped_projects = policy.apply_scope(Project, type: :relation, name: :group_projects,
                                                  scope_options: { group: })

    assert_equal 4, scoped_projects.count

    assert scoped_projects.include?(projects(:projectAlpha))
    assert scoped_projects.include?(projects(:projectAlpha1))
    assert scoped_projects.include?(projects(:projectBravo))
    assert scoped_projects.include?(projects(:projectCharlie))
  end
end
