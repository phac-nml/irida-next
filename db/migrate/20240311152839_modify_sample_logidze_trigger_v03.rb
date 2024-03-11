# frozen_string_literal: true

# Migration to modify sample logidze trigger
class ModifySampleLogidzeTriggerV03 < ActiveRecord::Migration[7.1]
  def change
    update_trigger :logidze_on_samples, on: :samples, version: 3
  end
end
