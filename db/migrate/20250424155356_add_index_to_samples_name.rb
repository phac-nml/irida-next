# frozen_string_literal: true

# adds a index to name column using gist to improve searching
class AddIndexToSamplesName < ActiveRecord::Migration[8.0]
  def change
    enable_extension :pg_trgm

    add_index :samples, :name, opclass: :gist_trgm_ops, using: :gist
    add_index :samples, :puid, name: 'index_samples_on_puid_gist', opclass: :gist_trgm_ops, using: :gist
  end
end
