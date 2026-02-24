# frozen_string_literal: true

# Create global notifications table.
class CreateGlobalNotifications < ActiveRecord::Migration[8.0]
  ENABLED_INDEX = 'index_global_notifications_on_enabled_when_enabled'
  SINGLETON_GUARD_CHECK = "singleton_guard = 'global'"
  STYLE_CHECK = "style IN ('info', 'warning', 'danger', 'success')"

  def change
    create_global_notifications_table
    add_enabled_index
    add_constraints
  end

  private

  def create_global_notifications_table
    create_table :global_notifications do |t|
      t.string :singleton_guard, null: false, default: 'global'
      t.boolean :enabled, null: false, default: true
      t.string :style, null: false, default: 'info'
      t.jsonb :messages, null: false, default: {}

      t.timestamps
    end
  end

  def add_enabled_index
    add_index :global_notifications,
              :enabled,
              unique: true,
              where: 'enabled = true',
              name: ENABLED_INDEX
  end

  def add_constraints
    add_check_constraint :global_notifications,
                         SINGLETON_GUARD_CHECK,
                         name: 'global_notifications_singleton_guard_check'
    add_check_constraint :global_notifications,
                         STYLE_CHECK,
                         name: 'global_notifications_style_check'
  end
end
