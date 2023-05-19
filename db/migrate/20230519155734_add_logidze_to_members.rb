class AddLogidzeToMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :members, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_members, on: :members
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_members" on "members";
        SQL
      end
    end
  end
end
