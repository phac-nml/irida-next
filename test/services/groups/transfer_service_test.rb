# frozen_string_literal: true

require 'test_helper'

module Groups
  class TransferServiceTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

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
    end

    test 'transfer group to same group' do
      assert_not Groups::TransferService.new(@group, @john_doe).execute(@group)
    end

    test 'transfer group to namespace containing group' do
      subgroup_one = groups(:subgroup1)

      assert_not Groups::TransferService.new(subgroup_one, @john_doe).execute(@group)
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
    end

    test 'transfer group without target namespace permission' do
      new_namespace = namespaces_user_namespaces(:jane_doe_namespace)

      assert_raises(ActionPolicy::Unauthorized) do
        Groups::TransferService.new(@group, @john_doe).execute(new_namespace)
      end
    end

    test 'authorize allowed to transfer group with permission' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_authorized_to(:transfer?, @group,
                           with: GroupPolicy,
                           context: { user: @john_doe }) do
        Groups::TransferService.new(@group,
                                    @john_doe).execute(new_namespace)
      end
    end

    test 'authorize allowed to transfer group into namespace' do
      new_namespace = namespaces_user_namespaces(:john_doe_namespace)

      assert_authorized_to(:transfer_into_namespace?, new_namespace,
                           with: Namespaces::UserNamespacePolicy,
                           context: { user: @john_doe }) do
        Groups::TransferService.new(@group,
                                    @john_doe).execute(new_namespace)
      end
    end
  end
end
