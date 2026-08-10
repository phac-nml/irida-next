# frozen_string_literal: true

# Migration to add deletion_reason column to samples table
class AddDeletionReasonToSamples < ActiveRecord::Migration[8.1]
  def change
    add_column :samples, :deletion_reason, :text, comment: 'Reason for deletion of the sample'
  end
end
