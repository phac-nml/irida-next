# frozen_string_literal: true

require 'test_helper'

module Groups
  class TransferServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @group = groups(:group_one)

      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
    end

    test 'transfer group with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: new_namespace.id }.merge(group: @group))
      assert_changes -> { @group.parent }, to: new_namespace do
        Groups::TransferService.new(@group, @john_doe, transfer_form).execute
      end

      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'transfer group without specifying new namespace' do
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: '' }.merge(group: @group))
      assert_not Groups::TransferService.new(@group, @john_doe, transfer_form).execute
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group to same group' do
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: @group.id }.merge(group: @group))
      assert_not Groups::TransferService.new(@group, @john_doe, transfer_form).execute
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group to same parent' do
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: @subgroup12a.parent_id }.merge(group: @subgroup12a))
      assert_not Groups::TransferService.new(@subgroup12a, @john_doe, transfer_form).execute
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group to namespace containing group' do
      subgroup_one = groups(:subgroup1)
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: @group.id }.merge(group: subgroup_one))

      assert_not Groups::TransferService.new(subgroup_one, @john_doe, transfer_form).execute
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'transfer group without group permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: new_namespace.id }
.merge(group: @group))
      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::TransferService.new(@group, @jane_doe, transfer_form).execute
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
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: new_namespace.id }.merge(group: @group))
      assert_raises(ActionPolicy::Unauthorized) do
        Groups::TransferService.new(@group, @john_doe, transfer_form).execute
      end
      assert_no_enqueued_jobs(except: Turbo::Streams::BroadcastStreamJob)
    end

    test 'authorize allowed to transfer group with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: new_namespace.id }.merge(group: @group))
      assert_authorized_to(:transfer?, @group,
                           with: GroupPolicy,
                           context: { user: @john_doe }) do
        Groups::TransferService.new(@group,
                                    @john_doe, transfer_form).execute
      end
      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'authorize allowed to transfer group into namespace' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)
      transfer_form = ::Groups::TransferForm.new({ new_parent_id: new_namespace.id }.merge(group: @group))
      assert_authorized_to(:transfer_into_namespace?, new_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @john_doe }) do
        Groups::TransferService.new(@group,
                                    @john_doe, transfer_form).execute
      end
      assert_enqueued_with(job: UpdateMembershipsJob)
    end

    test 'metadata summary updates after group transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        assert_no_changes -> { @subgroup12aa.reload.metadata_summary } do
          transfer_form = ::Groups::TransferForm.new({ new_parent_id: @subgroup12b.id }
.merge(group: @subgroup12aa))
          Groups::TransferService.new(@subgroup12aa, @john_doe, transfer_form).execute
        end
      end

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        assert_no_changes -> { @subgroup12aa.reload.metadata_summary } do
          assert_no_changes -> { @subgroup12b.reload.metadata_summary } do
            transfer_form = ::Groups::TransferForm.new({ new_parent_id: @subgroup12a.id }.merge(group: @subgroup12b))
            Groups::TransferService.new(@subgroup12b, @john_doe, transfer_form).execute
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
      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        assert_no_changes -> { @subgroup12aa.reload.samples_count } do
          transfer_form = ::Groups::TransferForm.new({ new_parent_id: @subgroup12b.id }.merge(group: @subgroup12aa))
          Groups::TransferService.new(@subgroup12aa, @john_doe, transfer_form).execute
        end
      end

      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(3, @subgroup12b.reload.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        assert_no_changes -> { @subgroup12aa.reload.samples_count } do
          assert_no_changes -> { @subgroup12b.reload.samples_count } do
            transfer_form = ::Groups::TransferForm.new({ new_parent_id: @subgroup12a.id }.merge(group: @subgroup12b))
            Groups::TransferService.new(@subgroup12b, @john_doe, transfer_form).execute
          end
        end
      end

      assert_equal(4, @subgroup12a.reload.samples_count)
    end

    test 'transfer private group to public parent group' do
      new_parent_group = groups(:public_group1)
      assert_not @subgroup12a.public?
      assert new_parent_group.public?

      transfer_form = ::Groups::TransferForm.new({ new_parent_id: new_parent_group.id }.merge(group: @subgroup12a))
      Groups::TransferService.new(@subgroup12a, @john_doe, transfer_form).execute

      assert @subgroup12a.reload.public?
    end
  end
end
