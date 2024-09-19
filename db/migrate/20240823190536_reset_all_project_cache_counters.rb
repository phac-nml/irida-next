# frozen_string_literal: true

# Migration to reset samples_count to the actual count of project samples, for each project
class ResetAllProjectCacheCounters < ActiveRecord::Migration[7.2]
  def up
    Project.all.each do |project|
      Project.reset_counters(project.id, :samples)
    end
  end
end
