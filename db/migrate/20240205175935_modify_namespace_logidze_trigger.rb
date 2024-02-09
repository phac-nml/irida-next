# frozen_string_literal: true

# Migration to modify namespace logidze trigger
class ModifyNamespaceLogidzeTrigger < ActiveRecord::Migration[7.1]
  def change
    update_trigger :logidze_on_namespaces, on: :namespaces, version: 2
  end
end
