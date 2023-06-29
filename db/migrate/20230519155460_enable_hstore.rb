# frozen_string_literal: true

#
# migration to enable logidze hstore
class EnableHstore < ActiveRecord::Migration[7.0]
  def change
    enable_extension :hstore
  end
end
