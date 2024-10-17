# frozen_string_literal: true

# migration to reset the samples_count to the total number of samples found in all
# subgroups and projects, for each group
class ResetAllGroupSamplesCounters < ActiveRecord::Migration[7.2]
  def up
    Group.all.each do |group|
      group.samples_count = Project.joins(:namespace).where(namespace: { parent_id: group.self_and_descendants })
                                   .select(:samples_count).pluck(:samples_count).sum
      group.save!
    end
  end
end
