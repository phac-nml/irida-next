# frozen_string_literal: true

# Migration to add Namespace Bots join table
class CreateNamespaceBots < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/MethodLength
    create_table :namespace_bots do |t|
      t.bigint :user_id, null: false
      t.bigint :namespace_id, null: false
      t.datetime :deleted_at
      t.jsonb :log_data
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_namespace_bots, on: :namespace_bots
      end

      dir.down do
        execute <<~SQL.squish
          DROP TRIGGER IF EXISTS "logidze_on_namespace_bots" on "namespace_bots";
        SQL
      end
    end

    add_index :namespace_bots, %i[user_id namespace_id],
              unique: true,
              name: 'index_bot_user_with_namespace'
    add_index :namespace_bots, :deleted_at
  end
end
