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
      new_namespace = groups(:group_eight)
      owner_user = users(:james_doe)
      maintainer_user = users(:joan_doe)
      guest_user = users(:ryan_doe)

      assert_nil @group.parent
      assert_equal Member::AccessLevel::OWNER,
                   @group.group_members.where(user_id: owner_user.id).first.access_level
      assert_equal Member::AccessLevel::MAINTAINER,
                   @group.group_members.where(user_id: maintainer_user.id).first.access_level
      assert_equal Member::AccessLevel::GUEST,
                   @group.group_members.where(user_id: guest_user.id).first.access_level
      (Namespace::MAX_ANCESTORS - 1).times do |n|
        assert_equal Member::AccessLevel::GUEST,
                     groups("subgroup#{n + 1}").group_members.where(user_id: guest_user.id).first.access_level
      end

      Groups::TransferService.new(@group, @john_doe).execute(new_namespace)

      assert_equal @group.parent, new_namespace
      assert_equal Member::AccessLevel::OWNER,
                   @group.group_members.where(user_id: owner_user.id).first.access_level
      assert_equal Member::AccessLevel::MAINTAINER,
                   @group.group_members.where(user_id: maintainer_user.id).first.access_level
      assert_equal Member::AccessLevel::MAINTAINER,
                   @group.group_members.where(user_id: guest_user.id).first.access_level
      (Namespace::MAX_ANCESTORS - 1).times do |n|
        assert_equal Member::AccessLevel::MAINTAINER,
                     groups("subgroup#{n + 1}").group_members.where(user_id: guest_user.id).first.access_level
      end
    end

    test 'transfer group into subgroup with permission' do
      group = groups(:group_ten)
      new_namespace = groups(:subgroup_one_group_nine)
      new_namespace_parent = groups(:group_nine)
      user = users(:james_doe)

      assert_nil group.parent
      assert_equal Member::AccessLevel::GUEST,
                   group.group_members.where(user_id: user.id).first.access_level
      assert_equal Member::AccessLevel::OWNER,
                   new_namespace.group_members.where(user_id: user.id).first.access_level
      assert_equal Member::AccessLevel::MAINTAINER,
                   new_namespace_parent.group_members.where(user_id: user.id).first.access_level

      Groups::TransferService.new(group, @john_doe).execute(new_namespace)

      assert_equal group.parent, new_namespace
      assert_equal Member::AccessLevel::OWNER,
                   group.group_members.where(user_id: user.id).first.access_level
      assert_equal Member::AccessLevel::OWNER,
                   new_namespace.group_members.where(user_id: user.id).first.access_level
      assert_equal Member::AccessLevel::MAINTAINER,
                   new_namespace_parent.group_members.where(user_id: user.id).first.access_level
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
