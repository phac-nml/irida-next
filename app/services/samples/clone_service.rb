# frozen_string_literal: true

module Samples
  # Service used to clone samples
  class CloneService < BaseProjectService
    def execute(new_project_id, sample_ids) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      authorize! @project, to: :clone_sample?

      @new_project = Project.find_by(id: new_project_id)
      authorize! @new_project, to: :clone_sample_into_project?

      cloned_sample_ids = {}
      sample_ids.each do |sample_id|
        sample = Sample.find_by(id: sample_id, project_id: @project.id)
        clone = sample.dup
        clone.project_id = @new_project.id
        files = []
        sample.attachments.each do |attachment|
          files << attachment.file.blob
        end
        Attachments::CreateService.new(@current_user, clone, { files: }).execute
        clone.save!
        cloned_sample_ids[sample.id] = clone.id
      rescue StandardError => e
        project.errors.add(:base, e)
      end
      cloned_sample_ids
    end
  end
end
