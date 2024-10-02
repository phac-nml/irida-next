# frozen_string_literal: true

require 'test_helper'

class NamespacePolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:david_doe)
    @policy = NamespacePolicy.new(user: @user)
  end

  test 'named scope with expired memberships' do
    group_member = members(:group_four_member_david_doe)
    group_member.expires_at = 10.days.ago.to_date
    group_member.save

    scoped_namespaces = @policy.apply_scope(Namespace, type: :relation, name: :manageable)

    assert_equal 1, scoped_namespaces.count

    scoped_namespaces_names = scoped_namespaces.pluck(:name)
    assert_not scoped_namespaces_names.include?(groups(:david_doe_group_four).name)
  end

  test 'named scope without modify access to namespace via namespace group link' do
    scoped_namespaces = @policy.apply_scope(Namespace, type: :relation, name: :manageable)
    user_namespace = namespaces_user_namespaces(:david_doe_namespace)
    group = groups(:david_doe_group_four)

    assert_equal 2, scoped_namespaces.count

    assert scoped_namespaces.include?(user_namespace)
    assert scoped_namespaces.include?(group)

    assert_equal scoped_namespaces[0].type, Namespaces::UserNamespace.sti_name
    assert_equal scoped_namespaces[0].name, 'david.doe@localhost'
    assert_equal scoped_namespaces[0].path, 'david.doe_at_localhost'

    assert_equal scoped_namespaces[1].type, Group.sti_name
    assert_equal scoped_namespaces[1].name, 'Group 4'
    assert_equal scoped_namespaces[1].path, 'group-4'
  end

  test 'named scope with modify access to namespace via many namespace group links' do
    user = users(:user26)
    policy = NamespacePolicy.new(user:)
    scoped_namespaces = policy.apply_scope(Namespace, type: :relation, name: :manageable)
    group_self_and_descendants_count = groups(:group_one).self_and_descendants.count

    actual_namespaces = scoped_namespaces.pluck(:name)
    expected_namespaces = [user.namespace.name]

    user_namespace_count = 1
    namespace = namespace_group_links(:namespace_group_link14).namespace

    linked_group_and_descendants = namespace.self_and_descendants.where(type: Group.sti_name)

    expected_namespaces << linked_group_and_descendants.pluck(:name) << user.groups.self_and_descendants.pluck(:name)
    expected_count = linked_group_and_descendants.count + user.groups.self_and_descendants.count + user_namespace_count

    assert_equal expected_count, scoped_namespaces.count
    assert_equal expected_count,
                 group_self_and_descendants_count + user.groups.self_and_descendants.count + user_namespace_count
    assert_equal expected_namespaces.flatten.sort, actual_namespaces.flatten.sort
  end

  test 'namespaces without and with manageable access via namespace group link' do
    user = users(:john_doe)
    namespace_group_link = namespace_group_links(:namespace_group_link4)

    policy = NamespacePolicy.new(user:)
    scoped_namespaces = policy.apply_scope(Namespace, type: :relation, name: :manageable)

    # John Doe has manageable access to 29 namespaces
    # (1 user namespace and 27 group namespaces)
    assert_equal 33, scoped_namespaces.count

    assert_not scoped_namespaces.include?(namespace_group_link.namespace)

    # Namespace group link group access level updated to MAINTAINER from ANALYST
    # which links David Doe's Group 4 to Subgroup 1 which is a subgroup under
    # Group 1 which John Doe is an OWNER
    namespace_group_link.group_access_level = Member::AccessLevel::MAINTAINER
    namespace_group_link.save

    scoped_namespaces = policy.apply_scope(Namespace, type: :relation, name: :manageable)

    # John Doe has manageable access to 30 namespaces (1 user namespace,
    # 29 group namespaces, and 1 group namespace via a namespace
    # group link)
    assert_equal 34, scoped_namespaces.count

    assert scoped_namespaces.include?(namespace_group_link.namespace)
  end

  test 'named scope with modify access to namespace via a namespace group link ' do
    user = users(:private_joan)
    policy = NamespacePolicy.new(user:)
    scoped_namespaces = policy.apply_scope(Namespace, type: :relation, name: :manageable)
    group_self_and_descendants_count = groups(:group_delta).self_and_descendants.count

    actual_namespaces = scoped_namespaces.pluck(:name)
    expected_namespaces = [user.namespace.name]

    assert_equal 5, actual_namespaces.length
    assert actual_namespaces.include?(namespaces_user_namespaces(:private_joan_namespace).name)
    assert actual_namespaces.include?(groups(:group_delta).name)
    assert actual_namespaces.include?(groups(:group_echo).name)
    assert actual_namespaces.include?(groups(:group_delta_subgroupA).name)
    assert actual_namespaces.include?(groups(:group_echo_subgroupB).name)

    user_namespace_count = 1
    namespace = namespace_group_links(:namespace_group_link15).namespace

    linked_group_and_descendants = namespace.self_and_descendants.where(type: Group.sti_name)

    expected_namespaces << linked_group_and_descendants.pluck(:name) << user.groups.self_and_descendants.pluck(:name)
    expected_count = linked_group_and_descendants.count + user.groups.self_and_descendants.count + user_namespace_count

    assert_equal expected_count, scoped_namespaces.count
    assert_equal expected_count,
                 group_self_and_descendants_count + user.groups.self_and_descendants.count + user_namespace_count
    assert_equal expected_namespaces.flatten.sort, actual_namespaces.flatten.sort
  end

  test 'missing_named_scope' do
    exception = assert_raises ActionPolicy::UnknownNamedScope do
      @policy.apply_scope(Namespace, type: :relation, name: :own)
    end

    assert_equal(
      'Unknown named scope :own for type :relation for NamespacePolicy',
      exception.message
    )
  end

  test 'missing_scope_type' do
    exception = assert_raises ActionPolicy::UnknownScopeType do
      @policy.apply_scope(Namespace, type: :nonexistentscopetype)
    end

    assert_equal(
      'Unknown policy scope type :nonexistentscopetype for NamespacePolicy',
      exception.message
    )
  end
end
