# frozen_string_literal: true

# Add in numeric collation so that we can sort metadata fields naturally
class AddNumericCollationForNaturalSorting < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          CREATE COLLATION numeric (
            provider = 'icu',
            locale = 'en-u-kn-true'
          );
        SQL
      end

      dir.down do
        execute <<-SQL.squish
          DROP COLLATION IF EXISTS numeric;
        SQL
      end
    end
  end
end
