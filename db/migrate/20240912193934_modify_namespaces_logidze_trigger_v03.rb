# frozen_string_literal: true

# Migration to modify namespace logidze trigger for attachments_updated_at
class ModifyNamespacesLogidzeTriggerV03 < ActiveRecord::Migration[7.2]
  def change
    update_trigger :logidze_on_namespaces, on: :namespaces, version: 3
  end
end
