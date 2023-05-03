# frozen_string_literal: true

require 'test_helper'

class NamespaceTest < ActiveSupport::TestCase
  test 'cannot create with nil type' do
    namespace = Namespace.new(name: 'base', path: 'base')
    assert_not namespace.valid?, 'namespace is valid without a type'
    assert_not_nil namespace.errors[:type], 'no validation error for type present'
  end

  test '#self_and_ancestors when collection is empty' do
    assert_equal [], Namespace.none.self_and_ancestors
  end

  test '#self_and_ancestors when collection is non empty' do
    assert_equal [groups(:group_one)], Group.where(id: groups(:group_one).id).self_and_ancestors
  end

  test '#self_and_decendants when collection is empty' do
    assert_equal [], Namespace.none.self_and_descendants
  end

  test '#self_and_descendants when collection is non empty' do
    assert_equal [groups(:group_three), groups(:subgroup_one_group_three)],
                 Group.where(id: groups(:group_three).id).self_and_descendants
  end
end
