# frozen_string_literal: true

require 'test_helper'
require Rails.root.join('db/migrate/20261105201436_add_traversal_ids_to_namespaces')

class AddTraversalIdsToNamespacesTest < ActiveSupport::TestCase
  setup do
    # Simulate the pre-migration schema so the migration's #up can be
    # exercised against fixture data that already has a namespace hierarchy.
    ActiveRecord::Base.connection.remove_column(:namespaces, :traversal_ids)
    Namespace.reset_column_information
  end

  teardown do
    # Transactional fixtures roll back DML, but the DDL change made in setup
    # must be undone explicitly so later tests see the real schema again.
    unless ActiveRecord::Base.connection.column_exists?(:namespaces, :traversal_ids)
      ActiveRecord::Base.connection.add_column(
        :namespaces, :traversal_ids, :uuid, array: true, default: [], null: false
      )
    end

    Namespace.reset_column_information
  end

  test 'backfills traversal_ids for root namespaces' do
    migrate_up

    group_twelve = reload(groups(:group_twelve))

    assert_equal [group_twelve.id], group_twelve.traversal_ids
  end

  test 'backfills traversal_ids for nested namespaces matching the parent chain' do
    migrate_up

    group_twelve = reload(groups(:group_twelve))
    subgroup_a = reload(groups(:subgroup_twelve_a))
    subgroup_a_a = reload(groups(:subgroup_twelve_a_a))

    assert_equal [group_twelve.id, subgroup_a.id], subgroup_a.traversal_ids
    assert_equal [group_twelve.id, subgroup_a.id, subgroup_a_a.id], subgroup_a_a.traversal_ids
  end

  test 'backfills traversal_ids for soft-deleted namespaces' do
    groups(:subgroup_twelve_a_a).destroy

    migrate_up

    group_twelve = reload(groups(:group_twelve))
    subgroup_a = reload(groups(:subgroup_twelve_a))
    subgroup_a_a = reload(groups(:subgroup_twelve_a_a))

    assert subgroup_a_a.deleted?
    assert_equal [group_twelve.id, subgroup_a.id, subgroup_a_a.id], subgroup_a_a.traversal_ids
  end

  test 'adds a gin index on traversal_ids' do
    migrate_up

    index = ActiveRecord::Base.connection.indexes(:namespaces).find { |i| i.columns == ['traversal_ids'] }

    assert_not_nil index
    assert_equal 'gin', index.using.to_s
  end

  test 'down removes the traversal_ids column' do
    migrate_up

    migration = AddTraversalIdsToNamespaces.new
    migration.suppress_messages { migration.down }

    assert_not ActiveRecord::Base.connection.column_exists?(:namespaces, :traversal_ids)
  end

  private

  def migrate_up
    migration = AddTraversalIdsToNamespaces.new
    migration.suppress_messages { migration.up }
    Namespace.reset_column_information
  end

  def reload(namespace)
    Namespace.with_deleted.find(namespace.id)
  end
end
