# frozen_string_literal: true

# Migration to modify sample logidze trigger
class ModifySampleLogidzeTrigger < ActiveRecord::Migration[7.1]
  def change
    update_trigger :logidze_on_samples, on: :samples, version: 2
  end
end
