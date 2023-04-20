# frozen_string_literal: true

# Migration to remove type from member
class RemoveTypeFromMember < ActiveRecord::Migration[7.0]
  def change
    remove_column :members, :type, :string
  end
end
