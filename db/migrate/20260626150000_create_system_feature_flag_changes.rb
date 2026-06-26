# frozen_string_literal: true

# Records administrator changes to admin-managed experimental feature flags.
class CreateSystemFeatureFlagChanges < ActiveRecord::Migration[8.1]
  def change # rubocop:disable Metrics/MethodLength
    create_table :system_feature_flag_changes, id: :uuid do |t|
      t.references :administrator, type: :uuid, null: false, index: false, foreign_key: { to_table: :users }
      t.string :feature_key, null: false
      t.string :action, null: false
      t.string :old_global_state, null: false
      t.string :new_global_state, null: false
      t.string :old_opt_in_state, null: false
      t.string :new_opt_in_state, null: false
      t.jsonb :cleared_gate_summary, null: false, default: {}
      t.string :environment, null: false

      t.timestamps
    end

    add_index :system_feature_flag_changes, %i[created_at id],
              order: { created_at: :desc, id: :desc },
              name: :idx_system_feature_flag_changes_newest_first
    add_index :system_feature_flag_changes, %i[feature_key created_at]
    add_index :system_feature_flag_changes, %i[administrator_id created_at]
  end
end
