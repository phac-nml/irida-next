# frozen_string_literal: true

require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @subgroup_one = groups(:subgroup1)
    @group_three = groups(:group_three)
    @group_three_subgroup1 = groups(:subgroup_one_group_three)
    @sample23 = samples(:sample23)
  end

  test 'valid group' do
    assert @group.valid?
  end

  test 'invalid if parent is not a group' do
    @group.parent = namespaces_user_namespaces(:john_doe_namespace)
    assert_not @group.valid?
    assert_not_nil @group.errors[:parent_id]
  end

  test 'invalid if more than 9 ancestors' do
    @subgroup = groups(:subgroup10)
    assert_not @subgroup.valid?, 'subgroup is valid with more than 9 ancestors'
    assert_not_nil @subgroup.errors[:parent_id], 'no validation error for parent'
  end

  test '#ancestors' do
    assert_equal [@group], @subgroup_one.ancestors
  end

  test '#ancestor_ids' do
    assert_equal [@group.id], @subgroup_one.ancestor_ids.pluck(:id)
  end

  test '#self_and_ancestors' do
    assert_includes @subgroup_one.self_and_ancestors, @subgroup_one
    assert_includes @subgroup_one.self_and_ancestors, @group
    assert_equal 2, @subgroup_one.self_and_ancestors.count
  end

  test '#descendants' do
    assert_includes @group_three.descendants, groups(:subgroup_one_group_three)
    assert_equal 1, @group_three.descendants.count
  end

  test '#self_and_descendants' do
    assert_includes @group_three.self_and_descendants, @group_three
    assert_includes @group_three.self_and_descendants, groups(:subgroup_one_group_three)
    assert_equal 2, @group_three.self_and_descendants.count
  end

  test '#human_name' do
    assert_equal @group.route.name, @group.human_name
  end

  test '#group_namespace?' do
    assert @group.group_namespace?
  end

  test '#project_namespace?' do
    assert_not @group.project_namespace?
  end

  test '#user_namespace?' do
    assert_not @group.user_namespace?
  end

  test '#owner_required?' do
    assert_not @group.owner_required?
  end

  test '#validate_type' do
    assert_nil @group.validate_type
  end

  test '#validate_parent_type' do
    assert_nil @group.validate_parent_type
  end

  test '#full_name' do
    assert_equal @group.route.name, @group.full_name
  end

  test '#full_path' do
    assert_equal @group.route.path, @group.full_path
  end

  test '#abbreviated_path' do
    assert_equal 'g/subgroup-1', @subgroup_one.abbreviated_path
  end

  test '#abbreviated_path with nested group' do
    assert_equal 'g/s/s/s/s/s/s/s/s/s/subgroup-10', groups('subgroup10').abbreviated_path
  end

  test '#destroy removes descendant groups, project namespaces, projects, and members' do
    self_and_descendants_count = @group_three.self_and_descendants.count
    project_namespaces = Namespaces::ProjectNamespace.where(parent: @group_three.self_and_descendants)
    projects_count = project_namespaces.count
    members_count = Member.where(namespace: @group_three.self_and_descendants).count +
                    Member.where(namespace: project_namespaces).count
    assert_difference(
      -> { Group.count } => (self_and_descendants_count * -1),
      -> { Namespaces::ProjectNamespace.count } => (projects_count * -1),
      -> { Project.count } => (projects_count * -1),
      -> { Member.count } => (members_count * -1)
    ) do
      @group_three.destroy
    end
  end

  test '#destroy removes descendant groups, project namespaces, projects, and members, then they are restored' do
    self_and_descendants_count = @group_three.self_and_descendants.count
    project_namespaces = Namespaces::ProjectNamespace.where(parent: @group_three.self_and_descendants)
    projects_count = project_namespaces.count
    members_count = Member.where(namespace: @group_three.self_and_descendants).count +
                    Member.where(namespace: project_namespaces).count
    assert_difference(
      -> { Group.count } => (self_and_descendants_count * -1),
      -> { Namespaces::ProjectNamespace.count } => (projects_count * -1),
      -> { Project.count } => (projects_count * -1),
      -> { Member.count } => (members_count * -1)
    ) do
      @group_three.destroy
    end

    assert_difference(
      -> { Group.count } => (self_and_descendants_count * +1),
      -> { Namespaces::ProjectNamespace.count } => (projects_count * +1),
      -> { Project.count } => (projects_count * +1),
      -> { Member.count } => (members_count * +1)
    ) do
      Group.restore(@group_three.id, recursive: true)
    end
  end

  test 'get ancestor namespace_group_links for subgroup' do
    subgroup2 = groups(:subgroup2)

    group_group_link1 = namespace_group_links(:namespace_group_link5)

    group_group_link2 = namespace_group_links(:namespace_group_link6)

    group_group_link3 = namespace_group_links(:namespace_group_link7)

    group_group_links = subgroup2.shared_with_group_links.of_ancestors

    assert_equal 4, group_group_links.count

    assert group_group_links.include?(group_group_link1)
    assert group_group_links.include?(group_group_link2)
    assert group_group_links.include?(namespace_group_links(:namespace_group_link2))
    assert group_group_links.include?(namespace_group_links(:namespace_group_link14))
    assert_not group_group_links.include?(group_group_link3)
  end

  test 'get self and ancestor namespace_group_links for subgroup' do
    subgroup2 = groups(:subgroup2)

    group_group_link1 = namespace_group_links(:namespace_group_link5)

    group_group_link2 = namespace_group_links(:namespace_group_link6)

    group_group_link3 = namespace_group_links(:namespace_group_link7)

    group_group_links = subgroup2.shared_with_group_links.of_ancestors_and_self

    assert_equal 5, group_group_links.count

    assert group_group_links.include?(group_group_link1)
    assert group_group_links.include?(group_group_link2)
    assert group_group_links.include?(group_group_link3)
    assert group_group_links.include?(namespace_group_links(:namespace_group_link2))
    assert group_group_links.include?(namespace_group_links(:namespace_group_link14))
  end

  test 'group should have metadata summary with metadata fields and their counts from projects within' do
    expected_metadata_summary = @group.metadata_summary
    actual_metadata_summary = {}

    group_project_namespaces = @group.project_namespaces
    group_project_namespaces.each do |gpn|
      actual_metadata_summary.merge!(gpn.metadata_summary) { |_key, old_value, new_value| old_value + new_value }
    end

    assert_equal expected_metadata_summary, actual_metadata_summary
  end

  test 'group has a puid' do
    assert @group.has_attribute?(:puid)
  end

  test '#model_prefix' do
    assert_equal 'GRP', Group.model_prefix
  end

  test '#metadata_summary' do
    assert_equal %w[metadatafield1 metadatafield2 unique.metadata.field], @group.metadata_fields
  end

  test '#metadata_summary incorporates fields from shared groups' do
    assert_equal %w[metadatafield1 metadatafield2 unique.metadata.field], groups(:david_doe_group_four).metadata_fields
  end

  test '#metadata_summary incorporates fields from shared projects' do
    assert_equal %w[metadatafield1 metadatafield2], groups(:group_alpha).metadata_fields
  end

  test '#has_samples' do
    assert @group.has_samples?
  end

  test 'has_samples should return true for a group with only samples shared from other groups' do
    group = groups(:group_kilo)
    assert group.has_samples?
  end

  test 'has_samples should return false for a group with no direct or shared samples' do
    group = groups(:group_two)
    assert_not group.has_samples?
  end

  test 'group with no samples should have aggregated_samples_count equal to shared groups samples_count' do
    group = groups(:group_kilo)
    shared_group = groups(:group_twelve)

    assert_equal 0, group.samples_count
    assert_equal 4, shared_group.samples_count
    assert_equal shared_group.samples_count, group.aggregated_samples_count
  end

  test 'group with nothing being shared to, aggregated_samples_count should equal samples_count' do
    group12 = groups(:group_twelve)

    assert_equal 4, group12.samples_count
    assert_equal group12.samples_count, group12.aggregated_samples_count
  end

  test 'aggregated_samples_count should equal samples_count plus samples_counts of groups and projects shared to it' do
    group_alpha = groups(:group_alpha)
    shared_group = groups(:group_charlie)
    shared_project = projects(:projectBravo)
    group_alpha_samples_count = group_alpha.samples_count
    shared_group_samples_count = shared_group.samples_count
    shared_project_samples_count = shared_project.samples.size
    aggregated_samples_count = group_alpha_samples_count + shared_group_samples_count + shared_project_samples_count

    assert_equal 2, group_alpha_samples_count
    assert_equal 1, shared_group_samples_count
    assert_equal 1, shared_project_samples_count
    assert_equal aggregated_samples_count, group_alpha.aggregated_samples_count
  end

  test 'group with a subproject as a shared project should not include subproject twice in aggregated_samples_count' do
    group = groups(:group_india)

    assert_equal 3, group.samples_count
    assert_equal group.samples_count, group.aggregated_samples_count
  end

  test 'group with a subgroup as a shared group should not include subgroup twice in aggregated_samples_count' do
    group = groups(:group_juliett)

    assert_equal 3, group.samples_count
    assert_equal group.samples_count, group.aggregated_samples_count
  end

  test 'aggregated_samples_count should not include shared projects that are descendants of groups in shared groups' do
    assert_equal 8, groups(:group_five).aggregated_samples_count
  end

  test 'aggregated_samples_count should not include shared groups that are descendants of groups in shared groups' do
    group = groups(:group_lima)
    shared_group = groups(:group_twelve)

    assert_equal 0, group.samples_count
    assert_equal 4, shared_group.samples_count
    assert_equal shared_group.samples_count, group.aggregated_samples_count
  end

  test 'shared group is an ancestor, aggregated_samples_count should not include ones own samples_count twice' do
    group = groups(:subgroup_mike_a)
    shared_group = groups(:group_mike)

    assert_equal 2, group.samples_count
    assert_equal 6, shared_group.samples_count
    assert_equal shared_group.samples_count, group.aggregated_samples_count
  end

  test 'shared project is in an ancestor group, should include it in aggregated_samples_count' do
    group = groups(:subgroup_mike_a_a)
    shared_project = projects(:projectMike)

    assert_equal 0, group.samples_count
    assert_equal 2, shared_project.samples.size
    assert_equal shared_project.samples.size, group.aggregated_samples_count
  end

  test 'aggregated_samples_count should include projects and groups shared with descendants' do
    group = groups(:group_oscar)
    subgroup = groups(:subgroup_oscar_a)

    assert_equal 0, group.samples_count
    assert_equal 0, subgroup.samples_count
    assert_equal 3, subgroup.aggregated_samples_count
    assert_equal subgroup.aggregated_samples_count, group.aggregated_samples_count
  end

  test 'aggregated_samples_count should not include shared projects/groups of shared groups' do
    group = groups(:group_papa)
    subgroup = groups(:subgroup_papa_a)
    shared_group = groups(:group_lima)

    assert_equal 0, group.samples_count
    assert_equal 0, shared_group.samples_count
    assert_equal 4, shared_group.aggregated_samples_count
    assert_equal 0, subgroup.samples_count
    assert_equal 0, subgroup.aggregated_samples_count
    assert_equal subgroup.aggregated_samples_count, group.aggregated_samples_count
  end

  test 'group with expired links should not include those samples to aggregated_samples_count' do
    group = groups(:subgroup_mike_b)
    shared_group = groups(:group_twelve)

    assert_equal 2, group.samples_count
    assert_equal 4, shared_group.samples_count
    assert_equal group.samples_count, group.aggregated_samples_count
  end

  test 'update samples_count by sample transfer' do
    project = projects(:project22)
    assert_difference -> { @group_three.reload.samples_count } => -1,
                      -> { @group_three_subgroup1.reload.samples_count } => -1 do
      @group_three_subgroup1.update_samples_count_by_transfer_service(project, 1)
    end
  end

  test 'update samples_count by sample deletion' do
    assert_difference -> { @group_three.reload.samples_count } => -1,
                      -> { @group_three_subgroup1.reload.samples_count } => -1 do
      @group_three_subgroup1.update_samples_count_by_destroy_service(1)
    end
  end

  test 'update samples_count by sample addition' do
    assert_difference -> { @group_three.reload.samples_count } => 1,
                      -> { @group_three_subgroup1.reload.samples_count } => 1 do
      @group_three_subgroup1.update_samples_count_by_addition_services(1)
    end
  end

  test 'samples_count for each group fixture should be correct' do
    # If you've added samples to fixtures, update the sample_count to the corresponding project/groups
    Group.find_each do |group|
      current_samples_count = group.samples_count
      expected_samples_count = Project.joins(:namespace).where(namespace: { parent_id: group.self_and_descendants })
                                      .select(:samples_count).pluck(:samples_count).sum

      assert_equal current_samples_count, expected_samples_count
    end
  end
end
