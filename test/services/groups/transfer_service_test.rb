# frozen_string_literal: true

require 'test_helper'

module Groups
  class TransferServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @group = groups(:group_one)
    end

    test 'transfer group with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)
      assert_changes -> { @group.parent }, to: new_namespace do
        Groups::TransferService.new(@group, @john_doe).execute(new_namespace)
      end

      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'transfer group without specifying new namespace' do
      assert_not Groups::TransferService.new(@group, @john_doe).execute(nil)
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group to same group' do
      assert_not Groups::TransferService.new(@group, @john_doe).execute(@group)
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group to namespace containing group' do
      subgroup_one = groups(:subgroup1)

      assert_not Groups::TransferService.new(subgroup_one, @john_doe).execute(@group)
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group without group permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)
      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::TransferService.new(@group, @jane_doe).execute(new_namespace)
      end
      assert_equal GroupPolicy, exception.policy
      assert_equal :transfer?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.transfer?',
                          name: @group.name),
                   exception.result.message
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group without target namespace permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)
      assert_raises(ActionPolicy::Unauthorized) do
        Groups::TransferService.new(@group, @john_doe).execute(new_namespace)
      end
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'authorize allowed to transfer group with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)
      assert_authorized_to(:transfer?, @group,
                           with: GroupPolicy,
                           context: { user: @john_doe }) do
        Groups::TransferService.new(@group,
                                    @john_doe).execute(new_namespace)
      end
      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'authorize allowed to transfer group into namespace' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)
      assert_authorized_to(:transfer_into_namespace?, new_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @john_doe }) do
        Groups::TransferService.new(@group,
                                    @john_doe).execute(new_namespace)
      end
      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'metadata summary updates after group transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        assert_no_changes -> { @subgroup12aa.reload.metadata_summary } do
          Groups::TransferService.new(@subgroup12aa, @john_doe).execute(@subgroup12b)
        end
      end

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        assert_no_changes -> { @subgroup12aa.reload.metadata_summary } do
          assert_no_changes -> { @subgroup12b.reload.metadata_summary } do
            Groups::TransferService.new(@subgroup12b, @john_doe).execute(@subgroup12a)
          end
        end
      end

      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @subgroup12a.reload.metadata_summary)
    end

    test 'samples count updates after group transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)

      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        assert_no_changes -> { @subgroup12aa.reload.samples_count } do
          Groups::TransferService.new(@subgroup12aa, @john_doe).execute(@subgroup12b)
        end
      end

      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(1, @subgroup12a.samples_count)
      assert_equal(3, @subgroup12b.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        assert_no_changes -> { @subgroup12aa.reload.samples_count } do
          assert_no_changes -> { @subgroup12b.reload.samples_count } do
            Groups::TransferService.new(@subgroup12b, @john_doe).execute(@subgroup12a)
          end
        end
      end

      assert_equal(4, @subgroup12a.reload.samples_count)
    end
  end
end
