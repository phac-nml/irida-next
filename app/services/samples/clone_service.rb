# frozen_string_literal: true

module Samples
  # Service used to clone samples
  class CloneService < BaseProjectService
    def execute(new_project_id, sample_ids)
      @new_project = Project.find_by(id: new_project_id)

      cloned_sample_ids = {}

      sample_ids.each do |sample_id|
        sample = Sample.find_by(id: sample_id, project_id: @project.id)
        clone = sample.dup
        clone.project_id = @new_project.id
        clone.save
        cloned_sample_ids[sample.id] = clone.id
        # clone attachments
      end
      cloned_sample_ids
    end
  end
end
