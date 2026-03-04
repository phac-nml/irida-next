# frozen_string_literal: true

# Create site banners table.
class CreateSiteBanners < ActiveRecord::Migration[8.0]
  ENABLED_INDEX = 'index_site_banners_on_enabled_when_enabled'
  SINGLETON_GUARD_CHECK = "singleton_guard = 'global'"
  STYLE_CHECK = "style IN ('info', 'warning', 'danger', 'success')"

  def change
    create_site_banners_table
    add_enabled_index
    add_constraints
  end

  private

  def create_site_banners_table
    create_table :site_banners do |t|
      t.string :singleton_guard, null: false, default: 'global'
      t.boolean :enabled, null: false, default: true
      t.string :style, null: false, default: 'info'
      t.jsonb :messages, null: false, default: {}

      t.timestamps
    end
  end

  def add_enabled_index
    add_index :site_banners,
              :enabled,
              unique: true,
              where: 'enabled = true',
              name: ENABLED_INDEX
  end

  def add_constraints
    add_check_constraint :site_banners,
                         SINGLETON_GUARD_CHECK,
                         name: 'site_banners_singleton_guard_check'
    add_check_constraint :site_banners,
                         STYLE_CHECK,
                         name: 'site_banners_style_check'
  end
end
