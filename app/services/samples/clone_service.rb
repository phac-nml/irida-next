# frozen_string_literal: true

module Samples
  # Service used to clone samples
  class CloneService < BaseProjectService
    CloneError = Class.new(StandardError)

    def execute(new_project_id, sample_ids)
      validate(new_project_id, sample_ids)

      authorize! @project, to: :clone_sample?

      @new_project = Project.find_by(id: new_project_id)
      authorize! @new_project, to: :clone_sample_into_project?

      clone_samples(@new_project, sample_ids)
    rescue Samples::CloneService::CloneError => e
      @project.errors.add(:base, e.message)
      {}
    end

    private

    def validate(new_project_id, sample_ids)
      raise CloneError, I18n.t('services.samples.clone.empty_new_project_id') if new_project_id.blank?

      raise CloneError, I18n.t('services.samples.clone.empty_sample_ids') if sample_ids.blank?

      return unless @project.id == new_project_id.to_i

      raise CloneError, I18n.t('services.samples.clone.same_project')
    end

    def clone_samples(new_project, sample_ids)
      cloned_sample_ids = {}
      sample_ids.each do |sample_id|
        cloned_sample_ids[sample_id] = clone_sample(new_project, sample_id)
      rescue ActiveRecord::RecordInvalid
        @project.errors.add(:sample, I18n.t('services.samples.clone.sample_exists', sample_id:))
      end
      cloned_sample_ids
    end

    def clone_sample(new_project, sample_id)
      sample = Sample.find_by(id: sample_id, project_id: @project.id)
      clone = Sample.new(name: sample.name, description: sample.description, project_id: new_project.id)
      clone_metadata(new_project, sample, clone) if clone.valid?
      clone_attachments(sample, clone) if clone.valid?
      clone.save! if @project.errors.empty?
      clone.id
    end

    def clone_metadata(new_project, sample, clone)
      metadata_changes = Samples::Metadata::UpdateService.new(new_project, clone, @current_user,
                                                              { 'metadata' => sample.metadata }).execute
      not_updated_metadata_changes = metadata_changes[:not_updated]
      return if not_updated_metadata_changes.empty?

      @project.errors.add(:sample,
                          I18n.t('services.samples.metadata.import_file.sample_metadata_fields_not_updated',
                                 sample_id:, metadata_fields: not_updated_metadata_changes.join(', ')))
    end

    def clone_attachments(sample, clone)
      files = []
      sample.attachments.each do |attachment|
        files << attachment.file.blob
      end
      Attachments::CreateService.new(@current_user, clone, { files: }).execute
    end
  end
end
