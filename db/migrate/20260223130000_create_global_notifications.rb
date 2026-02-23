# frozen_string_literal: true

# Create singleton global notifications table.
class CreateGlobalNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :global_notifications do |t|
      t.string :singleton_guard, null: false, default: 'global'
      t.boolean :enabled, null: false, default: false
      t.string :style, null: false, default: 'info'
      t.text :message_en
      t.text :message_fr

      t.timestamps
    end

    add_index :global_notifications, :singleton_guard, unique: true
    add_check_constraint :global_notifications,
                         "singleton_guard = 'global'",
                         name: 'global_notifications_singleton_guard_check'
    add_check_constraint :global_notifications,
                         "style IN ('info', 'warning', 'danger', 'success')",
                         name: 'global_notifications_style_check'
  end
end
