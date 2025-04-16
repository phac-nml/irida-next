# frozen_string_literal: true

# migration to recalculate group.samples_count after a bug was found where samples failing to create still increased
# samples_count
class RecalculateGroupSamplesCount < ActiveRecord::Migration[8.0]
  def change
    Group.all.each do |group|
      group.samples_count = 0
      group.save
    end

    Project.all.each do |project|
      next unless project.parent.group_namespace?

      project.parent.self_and_ancestors.each do |group|
        group.samples_count += project.samples_count
        group.save
      end
    end
  end
end
