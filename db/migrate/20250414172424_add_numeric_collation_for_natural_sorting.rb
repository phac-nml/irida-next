# frozen_string_literal: true

# Add in numeric collation so that we can sort fields naturally
class AddNumericCollationForNaturalSorting < ActiveRecord::Migration[8.0]
  def up
    begin
      execute <<-SQL.squish
        CREATE COLLATION IF NOT EXISTS numeric (provider = 'icu', locale = 'en-u-kn-true');
      SQL
    rescue StandardError => e
      abort <<~MESSAGE
        #{e.message}
      MESSAGE
    end

    change_column :samples, :name, :string, collation: 'numeric'
    change_column :namespaces, :name, :string, collation: 'numeric'
  end

  def down
    change_column :samples, :name, :string
    change_column :namespaces, :name, :string
  end
end
