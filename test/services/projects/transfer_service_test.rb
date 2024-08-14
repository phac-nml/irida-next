# frozen_string_literal: true

require 'test_helper'

module Projects
  class TransferServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @project = projects(:project1)
    end

    test 'transfer project with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_changes -> { @project.namespace.parent }, to: new_namespace do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end

      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'transfer project without specifying new namespace' do
      assert_not Projects::TransferService.new(@project, @john_doe).execute(nil)
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer project to namespace containing project' do
      group_one = groups(:group_one)

      assert_not Projects::TransferService.new(@project, @john_doe).execute(group_one)
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer project without project permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::TransferService.new(@project, @jane_doe).execute(new_namespace)
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :transfer?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.transfer?',
                          name: @project.name),
                   exception.result.message
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer project without target namespace permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)

      assert_raises(ActionPolicy::Unauthorized) do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end

      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer project to namespace containing project with same name' do
      project = projects(:john_doe_project2)
      group_one = groups(:group_one)

      assert_not Projects::TransferService.new(project, @john_doe).execute(group_one)
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'authorize allowed to transfer project with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_authorized_to(:transfer?, @project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Projects::TransferService.new(@project,
                                      @john_doe).execute(new_namespace)
      end
      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'authorize allowed to transfer to namespace' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_authorized_to(:transfer_into_namespace?, new_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @john_doe }) do
        Projects::TransferService.new(@project,
                                      @john_doe).execute(new_namespace)
      end
      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'project transfer changes logged using logidze' do
      project_namespace = @project.namespace
      project_namespace.create_logidze_snapshot!

      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size

      assert_changes -> { project_namespace.parent }, to: new_namespace do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end

      project_namespace.create_logidze_snapshot!

      assert_equal 2, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal groups(:group_one), project_namespace.at(version: 1).parent

      assert_equal new_namespace, project_namespace.at(version: 2).parent

      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'project transfer changes logged using logidze switch version' do
      project_namespace = @project.namespace
      project_namespace.create_logidze_snapshot!

      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_equal 1, project_namespace.log_data.version
      assert_equal 1, project_namespace.log_data.size

      assert_changes -> { project_namespace.parent }, to: new_namespace do
        Projects::TransferService.new(@project, @john_doe).execute(new_namespace)
      end

      project_namespace.create_logidze_snapshot!

      assert_equal 2, project_namespace.log_data.version
      assert_equal 2, project_namespace.log_data.size

      assert_equal groups(:group_one), project_namespace.at(version: 1).parent

      assert_equal new_namespace, project_namespace.at(version: 2).parent

      project_namespace.switch_to!(1)

      assert_equal groups(:group_one), project_namespace.parent

      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'metadata summary updates after project transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      @project31 = projects(:project31)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        assert_no_changes -> { @project31.namespace.reload.metadata_summary } do
          Projects::TransferService.new(@project31, @john_doe).execute(@subgroup12b)
        end
      end

      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)
    end

    test 'user namespace metadata summary does not update after project transfer' do
      @project31 = projects(:project31)

      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      Projects::TransferService.new(@project31, @john_doe).execute(new_namespace)

      new_namespace.reload
      assert_equal({}, new_namespace.metadata_summary)
    end
  end
end
