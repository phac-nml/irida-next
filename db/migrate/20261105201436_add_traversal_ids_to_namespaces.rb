# frozen_string_literal: true

# Adds a traversal_ids column to namespaces, storing the root-to-self chain of
# namespace ids for each namespace. This enables linear (array-based) ancestor
# and descendant lookups without joining through the routes table.
#
# Legacy rows are backfilled in the same migration via a recursive CTE so that
# every existing namespace has a correct traversal_ids value once this
# migration completes.
class AddTraversalIdsToNamespaces < ActiveRecord::Migration[8.1]
  def up
    add_column :namespaces, :traversal_ids, :uuid, array: true, default: [], null: false
    backfill_traversal_ids
    add_index :namespaces, :traversal_ids, using: :gin
  end

  def down
    remove_column :namespaces, :traversal_ids
  end

  private

  # Backfill traversal_ids for all existing namespaces (including
  # soft-deleted ones) by walking parent_id from each root down.
  def backfill_traversal_ids
    execute <<~SQL.squish
      WITH RECURSIVE namespace_tree AS (
        SELECT id, parent_id, ARRAY[id] AS traversal_ids
        FROM namespaces
        WHERE parent_id IS NULL

        UNION ALL

        SELECT n.id, n.parent_id, namespace_tree.traversal_ids || n.id
        FROM namespaces n
        INNER JOIN namespace_tree ON n.parent_id = namespace_tree.id
      )
      UPDATE namespaces
      SET traversal_ids = namespace_tree.traversal_ids
      FROM namespace_tree
      WHERE namespaces.id = namespace_tree.id
    SQL
  end
end
