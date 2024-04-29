# frozen_string_literal: true

require 'test_helper'

class ProjectNamespaceTest < ActiveSupport::TestCase
  def setup
    @project_namespace = namespaces_project_namespaces(:project1_namespace)
    @group_one = groups(:group_one)
  end

  test 'valid user namespace' do
    assert @project_namespace.valid?
  end

  test '#ancestors' do
    assert_equal [], @project_namespace.ancestors
  end

  test '#ancestor_ids' do
    assert_equal [], @project_namespace.ancestor_ids
  end

  test '#self_and_ancestors' do
    assert_equal [@project_namespace], @project_namespace.self_and_ancestors
  end

  test '#descendants' do
    assert_equal [],  @project_namespace.descendants
  end

  test '#self_and_descendants' do
    assert_equal [@project_namespace], @project_namespace.self_and_descendants
  end

  test '#human_name' do
    assert_equal @project_namespace.route.name, @project_namespace.human_name
  end

  test '#group_namespace?' do
    assert_not @project_namespace.group_namespace?
  end

  test '#project_namespace?' do
    assert @project_namespace.project_namespace?
  end

  test '#user_namespace?' do
    assert_not @project_namespace.user_namespace?
  end

  test '#owner_required?' do
    assert @project_namespace.owner_required?
  end

  test '#validate_type' do
    assert_nil @project_namespace.validate_type
  end

  test '#validate_parent_type' do
    assert_nil @project_namespace.validate_parent_type
  end

  test '#full_name' do
    assert_equal @project_namespace.route.name, @project_namespace.full_name
  end

  test '#full_path' do
    assert_equal @project_namespace.route.path, @project_namespace.full_path
  end

  test '#abbreviated_path' do
    assert_equal 'g/project-1', @project_namespace.abbreviated_path
  end

  test '#destroy removes dependant project, and members' do
    members_count = @project_namespace.project_members.count
    assert_difference(
      -> { Namespaces::ProjectNamespace.count } => -1,
      -> { Project.count } => -1,
      -> { Member.count } => (members_count * -1)
    ) do
      @project_namespace.destroy
    end
  end

  test '#destroy removes dependant project, and members, then they are restored' do
    members_count = @project_namespace.project_members.count
    assert_difference(
      -> { Namespaces::ProjectNamespace.count } => -1,
      -> { Project.count } => -1,
      -> { Member.count } => (members_count * -1)
    ) do
      @project_namespace.destroy
    end

    assert_difference(
      -> { Namespaces::ProjectNamespace.count } => +1,
      -> { Project.count } => +1,
      -> { Member.count } => (members_count * +1)
    ) do
      Namespaces::ProjectNamespace.restore(@project_namespace.id, recursive: true)
    end
  end

  test 'share project namespace with group and get ancestors namespace_group_links' do
    project_namespace = namespaces_project_namespaces(:project25_namespace)

    namespace_group_link1 = namespace_group_links(:namespace_group_link2)

    namespace_group_link2 = namespace_group_links(:namespace_group_link3)

    namespace_group_links = project_namespace.shared_with_group_links.of_ancestors

    assert namespace_group_links.include?(namespace_group_link1)
    assert_not namespace_group_links.include?(namespace_group_link2)
  end

  test 'share project namespace with group and get ancestor and self namespace_group_links' do
    project_namespace = namespaces_project_namespaces(:project25_namespace)

    namespace_group_link1 = namespace_group_links(:namespace_group_link2)

    namespace_group_link2 = namespace_group_links(:namespace_group_link3)

    namespace_group_links = project_namespace.shared_with_group_links.of_ancestors_and_self

    assert namespace_group_links.include?(namespace_group_link1)
    assert namespace_group_links.include?(namespace_group_link2)
  end

  test 'project namespace should have metadata summary with metadata fields and their counts' do
    assert_equal 2, @project_namespace.metadata_summary.count
    assert @project_namespace.metadata_summary.key?('metadatafield1')
    assert @project_namespace.metadata_summary.key?('metadatafield2')
    assert_equal 10, @project_namespace.metadata_summary['metadatafield1']
    assert_equal 35, @project_namespace.metadata_summary['metadatafield2']
  end

  test 'project has a puid' do
    assert @project_namespace.has_attribute?(:puid)
  end

  test '#model_prefix' do
    assert_equal 'PRJ', Namespaces::ProjectNamespace.model_prefix
  end

  test 'project namespace with automation_bot' do
    bot = users(:project1_automation_bot)
    assert_equal bot, @project_namespace.automation_bot
  end

  test 'project namespace without automation_bot' do
    namespace_without_bot = namespaces_project_namespaces(:project2_namespace)
    assert_nil namespace_without_bot.automation_bot
  end

  test 'update metadata summary by update service with valid metadata' do
    deleted_metadata = { 'metadatafield1' => 1 }
    added_metadata = { 'metadatafield2' => 1 }
    assert_equal 10, @project_namespace['metadata_summary']['metadatafield1']
    assert_equal 35, @project_namespace['metadata_summary']['metadatafield2']
    assert_equal 633, @project_namespace.parent.reload['metadata_summary']['metadatafield1']
    assert_equal 106, @project_namespace.parent.reload['metadata_summary']['metadatafield2']

    @project_namespace.update_metadata_summary_by_update_service(deleted_metadata, added_metadata)

    assert_equal 9, @project_namespace['metadata_summary']['metadatafield1']
    assert_equal 36, @project_namespace['metadata_summary']['metadatafield2']

    assert_equal 632, @project_namespace.parent.reload['metadata_summary']['metadatafield1']
    assert_equal 107, @project_namespace.parent.reload['metadata_summary']['metadatafield2']
  end

  test 'update metadata summary by update service with empty metadata' do
    deleted_metadata = {}
    added_metadata = {}

    assert_no_changes -> { @project_namespace.reload.metadata_summary } do
      assert_no_changes -> { @project_namespace.parent.reload.metadata_summary } do
        @project_namespace.update_metadata_summary_by_update_service(deleted_metadata, added_metadata)
      end
    end
  end

  test 'update metadata summary by sample transfer with valid metadata' do
    project29 = namespaces_project_namespaces(:project29_namespace)
    sample32 = samples(:sample32)

    assert_equal 10, @project_namespace['metadata_summary']['metadatafield1']
    assert_equal 35, @project_namespace['metadata_summary']['metadatafield2']
    assert_equal 633, @project_namespace.parent['metadata_summary']['metadatafield1']
    assert_equal 106, @project_namespace.parent['metadata_summary']['metadatafield2']

    assert_equal 1, project29['metadata_summary']['metadatafield1']
    assert_equal 1, project29['metadata_summary']['metadatafield2']

    project29.update_metadata_summary_by_sample_transfer([sample32.id], @project_namespace.project.id)

    assert_equal 11, @project_namespace.reload['metadata_summary']['metadatafield1']
    assert_equal 36, @project_namespace.reload['metadata_summary']['metadatafield2']
    assert_equal 634, @project_namespace.parent.reload['metadata_summary']['metadatafield1']
    assert_equal 107, @project_namespace.parent.reload['metadata_summary']['metadatafield2']

    assert_nil project29.reload['metadata_summary']['metadatafield1']
    assert_nil project29.reload['metadata_summary']['metadatafield2']
  end

  test 'update metadata summary by sample transfer with empty metadata' do
    project29 = namespaces_project_namespaces(:project29_namespace)
    sample32 = samples(:sample32)
    sample32.metadata = {}
    sample32.metadata_provenance = {}
    sample32.save

    assert_no_changes -> { @project_namespace.reload.metadata_summary } do
      assert_no_changes -> { @project_namespace.parent.reload.metadata_summary } do
        project29.update_metadata_summary_by_sample_transfer([sample32.id], @project_namespace.project.id)
      end
    end
  end

  test 'update metadata summary by sample deletion with valid metadata' do
    sample = samples(:sample30)

    assert_equal 10, @project_namespace['metadata_summary']['metadatafield1']
    assert_equal 35, @project_namespace['metadata_summary']['metadatafield2']
    assert_equal 633, @project_namespace.parent['metadata_summary']['metadatafield1']
    assert_equal 106, @project_namespace.parent['metadata_summary']['metadatafield2']

    @project_namespace.update_metadata_summary_by_sample_deletion(sample)

    assert_equal 9, @project_namespace.reload['metadata_summary']['metadatafield1']
    assert_equal 34, @project_namespace.reload['metadata_summary']['metadatafield2']
    assert_equal 632, @project_namespace.parent.reload['metadata_summary']['metadatafield1']
    assert_equal 105, @project_namespace.parent.reload['metadata_summary']['metadatafield2']
  end

  test 'update metadata summary by sample deletion with empty metadata' do
    sample = samples(:sample30)
    sample.metadata = {}
    sample.metadata_provenance = {}
    sample.save

    assert_no_changes -> { @project_namespace.reload.metadata_summary } do
      assert_no_changes -> { @project_namespace.parent.reload.metadata_summary } do
        @project_namespace.update_metadata_summary_by_sample_deletion(sample)
      end
    end
  end

  test 'update metadata summary by sample addition with valid metadata' do
    sample = Sample.new(
      name: 'New Sample',
      metadata: { metadatafield1: 'value1', metadatafield2: 'value2' },
      metadata_provenance: { 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                                   'updated_at' => DateTime.new(2000, 1, 1) },
                             'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                                   'updated_at' => DateTime.new(2000, 1, 1) } }
    )

    assert_equal 10, @project_namespace['metadata_summary']['metadatafield1']
    assert_equal 35, @project_namespace['metadata_summary']['metadatafield2']
    assert_equal 633, @project_namespace.parent['metadata_summary']['metadatafield1']
    assert_equal 106, @project_namespace.parent['metadata_summary']['metadatafield2']

    @project_namespace.update_metadata_summary_by_sample_addition(sample)

    assert_equal 11, @project_namespace.reload['metadata_summary']['metadatafield1']
    assert_equal 36, @project_namespace.reload['metadata_summary']['metadatafield2']
    assert_equal 634, @project_namespace.parent.reload['metadata_summary']['metadatafield1']
    assert_equal 107, @project_namespace.parent.reload['metadata_summary']['metadatafield2']
  end

  test 'update metadata summary by sample addition with empty metadata' do
    sample = Sample.new

    assert_no_changes -> { @project_namespace.reload.metadata_summary } do
      assert_no_changes -> { @project_namespace.parent.reload.metadata_summary } do
        @project_namespace.update_metadata_summary_by_sample_addition(sample)
      end
    end
  end
end
