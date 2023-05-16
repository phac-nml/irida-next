# frozen_string_literal: true

require 'test_helper'

class NamespacePolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:david_doe)
    @policy = NamespacePolicy.new(user: @user)
  end

  test 'named scope' do
    scoped_namespaces = @policy.apply_scope(Namespace, type: :relation, name: :manageable)

    assert_equal 2, scoped_namespaces.count

    assert_equal scoped_namespaces[0].type, Namespaces::UserNamespace.sti_name
    assert_equal scoped_namespaces[0].name, 'david.doe@localhost'
    assert_equal scoped_namespaces[0].path, 'david.doe_at_localhost'

    assert_equal scoped_namespaces[1].type, Group.sti_name
    assert_equal scoped_namespaces[1].name, 'Group 4'
    assert_equal scoped_namespaces[1].path, 'group-4'
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
